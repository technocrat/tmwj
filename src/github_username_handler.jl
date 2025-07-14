using HTTP
using JSON3

"""
    check_github_user(username::String; token::Union{String, Nothing}=nothing)

Check if a GitHub username exists by making a request to the GitHub API.
Returns a tuple (exists::Bool, user_data::Union{Dict, Nothing}, error_message::Union{String, Nothing})

# Arguments
- `username::String`: The GitHub username to check
- `token::Union{String, Nothing}`: Optional GitHub personal access token for higher rate limits

# Returns
- `exists::Bool`: Whether the user exists
- `user_data::Union{Dict, Nothing}`: User data if found, nothing otherwise
- `error_message::Union{String, Nothing}`: Error message if request failed

# Examples
```julia
# Check if a user exists
exists, user_data, error = check_github_user("octocat")

# Check with authentication token
exists, user_data, error = check_github_user("octocat", token="ghp_...")
```
"""
function check_github_user(username::String; token::Union{String, Nothing}=nothing)
    url = "https://api.github.com/users/$username"
    
    # Prepare headers
    headers = ["User-Agent" => "Julia-GitHub-User-Checker"]
    if !isnothing(token)
        push!(headers, "Authorization" => "token $token")
    end
    
    try
        response = HTTP.get(url, headers)
        
        if response.status == 200
            # User exists
            user_data = JSON3.read(response.body)
            return true, user_data, nothing
        elseif response.status == 404
            # User doesn't exist
            return false, nothing, nothing
        else
            # Other error
            return false, nothing, "HTTP $(response.status): $(response.body)"
        end
        
    catch e
        if e isa HTTP.ExceptionRequest.StatusError
            if e.status == 404
                # User doesn't exist
                return false, nothing, nothing
            else
                # Other HTTP error
                return false, nothing, "HTTP $(e.status): $(e.message)"
            end
        else
            # Network or other error
            return false, nothing, "Request failed: $(e)"
        end
    end
end

"""
    process_usernames(usernames::Vector{String}; token::Union{String, Nothing}=nothing)

Process a list of usernames and categorize them by existence status.
Handles 404 errors gracefully and continues processing.

# Arguments
- `usernames::Vector{String}`: List of usernames to check
- `token::Union{String, Nothing}`: Optional GitHub personal access token

# Returns
- `Dict{String, Vector{String}}`: Dictionary with keys "exists", "not_found", "errors"

# Examples
```julia
usernames = ["octocat", "nonexistent_user", "another_user"]
results = process_usernames(usernames)
```
"""
function process_usernames(usernames::Vector{String}; token::Union{String, Nothing}=nothing)
    results = Dict{String, Vector{String}}(
        "exists" => String[],
        "not_found" => String[],
        "errors" => String[]
    )
    
    println("Processing $(length(usernames)) usernames...")
    
    for (i, username) in enumerate(usernames)
        print("Checking $username ($(i)/$(length(usernames)))... ")
        
        exists, user_data, error_msg = check_github_user(username, token=token)
        
        if exists
            println("✓ EXISTS")
            push!(results["exists"], username)
        elseif isnothing(error_msg)
            println("✗ NOT FOUND (404)")
            push!(results["not_found"], username)
        else
            println("✗ ERROR: $error_msg")
            push!(results["errors"], username)
        end
        
        # Rate limiting: pause between requests to be respectful
        sleep(0.1)
    end
    
    return results
end

"""
    safe_username_check(username::String; token::Union{String, Nothing}=nothing)

Safe wrapper that traps 404 errors and continues execution.
Returns a simple boolean indicating if the user exists.

# Arguments
- `username::String`: The GitHub username to check
- `token::Union{String, Nothing}`: Optional GitHub personal access token

# Returns
- `Bool`: true if user exists, false otherwise (including 404 errors)

# Examples
```julia
# Simple check that won't throw errors
if safe_username_check("octocat")
    println("User exists!")
else
    println("User doesn't exist or error occurred")
end
```
"""
function safe_username_check(username::String; token::Union{String, Nothing}=nothing)
    exists, _, _ = check_github_user(username, token=token)
    return exists
end

# Example usage and testing
if abspath(PROGRAM_FILE) == @__FILE__
    println("=== GitHub Username Checker ===")
    
    # Test usernames (mix of existing and non-existing)
    test_usernames = [
        "octocat",           # Should exist
        "nonexistent_user_12345",  # Should not exist
        "github",            # Should exist
        "invalid_username_with_special_chars!",  # Should not exist
        "torvalds"           # Should exist
    ]
    
    println("\nTesting individual username checks:")
    for username in test_usernames
        exists, user_data, error = check_github_user(username)
        if exists
            println("✓ $username exists (Type: $(get(user_data, :type, "Unknown")))")
        elseif isnothing(error)
            println("✗ $username not found (404)")
        else
            println("✗ $username error: $error")
        end
    end
    
    println("\nTesting batch processing:")
    results = process_usernames(test_usernames)
    
    println("\n=== Results Summary ===")
    println("Exists: $(length(results["exists"])) - $(join(results["exists"], ", "))")
    println("Not Found: $(length(results["not_found"])) - $(join(results["not_found"], ", "))")
    println("Errors: $(length(results["errors"])) - $(join(results["errors"], ", "))")
    
    println("\n=== Safe Check Example ===")
    for username in test_usernames
        if safe_username_check(username)
            println("✓ $username exists")
        else
            println("✗ $username doesn't exist or error occurred")
        end
    end
end

# Export functions for use in other scripts
export check_github_user, process_usernames, safe_username_check 