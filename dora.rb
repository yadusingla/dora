require 'net/http'
require 'json'
require 'csv'
require 'uri'
require 'date'

# Replace with your GitHub Personal Access Token
GITHUB_TOKEN = ENV['GITHUB_TOKEN']

# Repository details
OWNER = ENV['GITHUB_OWNER'] # e.g., 'octocat'
REPOS = ENV['GITHUB_REPOS'].split(',') # e.g., ['Hello-World']

# Base URI for GitHub API
BASE_URI = URI('https://api.github.com')

# Headers for authentication
HEADERS = {
  'Authorization' => "token #{GITHUB_TOKEN}",
  'User-Agent' => 'Ruby Script',
  'Accept' => 'application/vnd.github.v3+json'
}

# Date range: from one week ago to now
now = (Date.today + 1).to_datetime.rfc3339
one_week_ago = (Date.today - 7).to_datetime.rfc3339

# Array to store PR data
pr_data_list = []

# Iterate over each repository
REPOS.each do |repo|
  puts "Processing repository: #{repo}"
  page = 1
  loop do
    puts "Fetching page #{page} of closed PRs for repository: #{repo}"
    # API endpoint for closed PRs
    uri = URI("#{BASE_URI}/repos/#{OWNER}/#{repo}/pulls")
    params = {
      state: 'closed',
      per_page: 100,
      page: page
    }
    uri.query = URI.encode_www_form(params)

    # HTTP GET request
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(uri, HEADERS)
      http.request(request)
    end

    # Check if response code is 200 but response body is empty
    if response.code == '200' && response.body.empty?
      puts "Response body is empty for repo #{repo}, page #{page}"
      break
    end

    # Error handling
    if response.code != '200'
      puts "Error fetching PRs for repo #{repo}, page #{page}: #{response.code} #{response.message}"
      break
    end

    pr_list = JSON.parse(response.body)

    # Break if no more PRs
    break if pr_list.empty?

    pr_list.each do |pr|
      # Check if PR is merged and within the last week
      if pr['merged_at'] && (pr['merged_at'] >= one_week_ago && pr['merged_at'] <= now)
        puts "Processing PR ##{pr['number']} from repository: #{repo}"
        # Fetch PR details (to get 'body' and 'merged_by' fields)
        pr_details_uri = URI(pr['url'])
        pr_details_response = Net::HTTP.start(pr_details_uri.host, pr_details_uri.port, use_ssl: true) do |http|
          request = Net::HTTP::Get.new(pr_details_uri, HEADERS)
          http.request(request)
        end

        # Error handling for PR details request
        next unless pr_details_response.code == '200'
        pr_details = JSON.parse(pr_details_response.body)

        # Fetch reviews to get reviewers
        reviews_uri = URI("#{pr['url']}/reviews")
        reviews_response = Net::HTTP.start(reviews_uri.host, reviews_uri.port, use_ssl: true) do |http|
          request = Net::HTTP::Get.new(reviews_uri, HEADERS)
          http.request(request)
        end

        reviews = JSON.parse(reviews_response.body)
        reviewers = reviews.map { |review| review['user']['login'] }.uniq

        # Fetch first commit date
        commits_uri = URI("#{pr['url']}/commits")
        commits_response = Net::HTTP.start(commits_uri.host, commits_uri.port, use_ssl: true) do |http|
          request = Net::HTTP::Get.new(commits_uri, HEADERS)
          http.request(request)
        end

        first_commit_date = nil
        if commits_response.code == '200'
          commits = JSON.parse(commits_response.body)
          first_commit_date = commits.first['commit']['author']['date'] if commits.any?
        end

        # Fetch first review comment date
        first_review_comment_date = reviews.first['submitted_at'] if reviews.any?

        # Store PR data
        branch_name = pr['head']['ref'].split('/').last
        branch_type = pr['head']['ref'].split('/').first
        pr_data = {
          'repo' => repo,
          'pr_number' => pr['number'],
          'pr_name' => pr['title'],
          'branch_type' => branch_type,
          'branch_name' => branch_name,
          'description' => pr_details['body'],
          'author' => pr['user']['login'],
          'reviewers' => reviewers.join(', '),
          'merged_by' => pr_details['merged_by'] ? pr_details['merged_by']['login'] : '',
          'merged_date' => pr['merged_at'],
          'created_date' => pr['created_at'],
          'first_commit_date' => first_commit_date,
          'first_review_comment_date' => first_review_comment_date,
        }
        pr_data_list << pr_data
        puts "Added PR ##{pr['number']} from repository: #{repo} to the list."
      end
    end

    # Check pagination headers to see if more pages exist
    link_header = response['Link']
    break unless link_header && link_header.include?('rel="next"')

    page += 1
  end
end

# Write data to CSV if PR data exists
if pr_data_list.any?
  puts "Writing data to 'merged_prs.csv'..."
  CSV.open('merged_prs.csv', 'w', write_headers: true, headers: pr_data_list.first.keys) do |csv|
    pr_data_list.each do |pr_data|
      csv << pr_data.values
    end
  end
  puts "Data extraction complete. Check 'merged_prs.csv' for the output."
else
  puts "No PR data found."
end