# Dora Script

This script is designed to fetch and process data from GitHub repositories, specifically focusing on closed pull requests (PRs) that were merged within the last week. The script retrieves various details about these PRs and writes the data to a CSV file.

## Prerequisites

- Ruby installed on your system
- GitHub Personal Access Token with appropriate permissions
- Environment variables set for GitHub token, owner, and repositories

## Environment Variables

Ensure the following environment variables are set:

- `GITHUB_TOKEN`: Your GitHub Personal Access Token
- `GITHUB_OWNER`: The owner of the repositories (e.g., 'octocat')
- `GITHUB_REPOS`: A comma-separated list of repository names (e.g., 'Hello-World,Another-Repo')

## How to Run

1. Clone the repository or download the script.
2. Navigate to the directory containing the script.
3. Set the required environment variables.
4. Run the script using the command:
   ```sh
   ruby dora.rb
   ```

## Script Details

The script performs the following steps:

1. Sets up the necessary headers for GitHub API authentication.
2. Defines the date range for fetching PRs (from one week ago to now).
3. Iterates over each repository specified in the `GITHUB_REPOS` environment variable.
4. Fetches closed PRs for each repository, page by page.
5. For each PR, checks if it was merged within the last week.
6. Fetches additional details for each PR, including:
   - PR description
   - Reviewers
   - First commit date
   - First review comment date
7. Stores the PR data in an array.
8. Writes the PR data to a CSV file named `merged_prs.csv`.

## Output

The script generates a CSV file named `merged_prs.csv` containing the following columns:

- `repo`: Repository name
- `pr_number`: Pull request number
- `pr_name`: Pull request title
- `branch_type`: Type of branch
- `branch_name`: Name of the branch
- `description`: Description of the pull request
- `author`: Author of the pull request
- `reviewers`: List of reviewers
- `merged_by`: User who merged the pull request
- `merged_date`: Date when the pull request was merged
- `created_date`: Date when the pull request was created
- `first_commit_date`: Date of the first commit in the pull request
- `first_review_comment_date`: Date of the first review comment

## Error Handling

The script includes error handling for various scenarios, such as:

- Empty response bodies
- Non-200 HTTP response codes
- Missing or invalid data

## Example

Here is an example of how to set the environment variables and run the script:
