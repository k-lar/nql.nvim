M = {}

-- Utility functions

--- Utility function for determining if a file is a markdown file
---@param filepath string
---@return boolean
local function is_markdown(filepath)
    if vim.filetype.match({ filename = filepath }) == "markdown" then
        return true
    end
    return false
end

--- Utility function for expanding environment variables
---@param filepath string
---@return string
local function expand_path(filepath)
    if filepath:sub(1, 1) == "$" then
        -- Extract the environment variable name
        local env_var = filepath:match("^%$(%w+)")
        local env_value = os.getenv(env_var)
        if env_value then
            -- INFO: :gsub returns 2 values but wrapping it in (), it discards all but the first value returned by :gsub
            return (filepath:gsub("^%$%w+", env_value))
        end
    end
    return filepath
end

--- Utility function for determining if a filepath is relative or absolute
---@param filepath string
---@return boolean
local function is_absolute_path(filepath)
    if filepath:sub(1, 1) == "$" then
        return true
    end
    -- Check if the path is absolute (Unix-like systems)
    if filepath:sub(1, 1) == "/" or filepath:sub(1, 1) == "~" then
        return true
    end
    -- Check if the path is absolute (Windows)
    if filepath:sub(2, 3) == ":/" or filepath:sub(2, 3) == ":\\" then
        return true
    end
    return false
end

-- Plugin config

--- An object to hold all relevant data for a query
---@class QueryContainer
---@field datatype DataType
---@field filepath string
---@field contents string[]
---@field enumerable boolean
---@field query_limit integer
---@field errors? string[]
local QueryContainer = {}
QueryContainer.__index = QueryContainer

---@enum DataType
DataType = {
    Tasks = 1,
    Bullet_points = 2,
    Headings = 3,
    Paragraphs = 4,
    Block_quotes = 5,
}

--- Initialize a query
---@param data_type DataType
---@return QueryContainer
function M.query(data_type)
    local query = setmetatable({
        datatype = data_type,
        filepath = "",
        contents = {},
        enumerable = true,
        query_limit = 0,
    }, QueryContainer)

    return query
end

--- Helper function to append an error message to self.errors
---@param self QueryContainer
---@param message string
function QueryContainer:append_error(message)
    if not self.errors then
        self.errors = { message }
    else
        table.insert(self.errors, message)
    end
end

--- Method to set the filepath in QueryContainer
---@param filepath string
---@return QueryContainer
function QueryContainer:from(filepath)
    if not is_markdown(filepath) then
        vim.notify(filepath .. " is not a markdown file.", vim.log.levels.WARN)
        self:append_error(filepath .. " is not a markdown file.")
        return self
    end

    filepath = expand_path(filepath)
    if not is_absolute_path(filepath) then
        -- Get the directory of the currently opened buffer
        local current_buffer_path = vim.api.nvim_buf_get_name(0)
        local current_buffer_dir = current_buffer_path:match("(.*/)")
        -- Prepend the current buffer's directory to the relative path
        filepath = current_buffer_dir .. filepath
    end

    if vim.fn.filereadable(vim.fn.expand(filepath)) == 0 then
        vim.notify(filepath .. " could not be found", vim.log.levels.WARN)
        self:append_error(filepath .. " could not be found")
        return self
    end

    self.filepath = filepath
    return self
end

--- Define a limit for the query
---@param self QueryContainer
---@param limit_num integer
---@return QueryContainer
function QueryContainer:limit(limit_num)
    if limit_num < 0 then
        vim.notify("Limit must be a positive integer", vim.log.levels.WARN)
        self:append_error("Limit must be a positive integer")
        return self
    end
    self.query_limit = limit_num
    return self
end

--- Method to define a condition for the query
---@param self QueryContainer
---@param condition function
---@return QueryContainer
-- TODO: Implement the where method
function QueryContainer:where(condition)
    return self
end

return M
