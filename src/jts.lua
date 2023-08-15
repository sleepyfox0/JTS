-------------------------------------------------------------
--
-- JACK THE STRIPPER
--
-- A lua code minimizer
--
-- Remove any empty line and comments from lua source files
-- Doesn't actually check the validity of lua code
-------------------------------------------------------------

-- Options
local help_on = false       -- display help?
local out_path = "out.lua"  -- output path
local path = nil            -- input file from command line

-- Utility Functions ----------------------------------------------
-- Trim a string
function trim(s)
    return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

-- Checks if a file exists at the specified path
function file_exist(path)
    local f = io.open(path, "r")
    if f~= nil then
        io.close(f)
        return true
    end
    return false
end
-- END utility ----------------------------------------------------

-- Usage Functions -------------------------------------------------
-- Split data into lines and remove the empty ones
function split_and_cut(data)
    local lines = {}
    for s in string.gmatch(data, "[^\r\n]+") do
        table.insert(lines, s)
    end
    return lines
end

-- Check if a block comment is opened
function is_block(line, i)
    local rv = false                -- return value
    local idx = i+1                 -- current id
    local s = line:sub(idx, idx)    -- character
    local ecnt = 0                  -- equals count
    if s ~= '[' then
        return false
    end

    -- This might be dangerous
    while true do
        idx = idx + 1
        s = line:sub(idx, idx)
        if s == '=' then
            ecnt = ecnt + 1
        elseif s == '[' then
            rv = true
            break
        else
            break
        end
    end
    return rv, ecnt
end

-- Check if a block comment is closed
function is_block_end(line, i, ecnt)
    local idx = i
    local s = line:sub(idx, idx)
    if s ~= ']' then
        return false
    end

    for j=1, ecnt do
        idx = idx - 1
        s = line:sub(idx, idx)
        if s ~= '=' then
            return false
        end
    end

    s = line:sub(idx-1, idx-1)
    if s ~= ']' then
        return false
    end
    return true 
end

-- Remove comments
-- Probably can be done with other methods, too
function handle_comments(lines)
    local new_lines = {}
    local cmt_cnt
    local mode = "normal"
    local b_cnt = 0
    for _, line in ipairs(lines) do
        cmt_cnt = 0
        local new_line = ""
        for i=1, #line do
            local chr = line:sub(i, i)
            if mode == "normal" then
                if chr == '-' then
                    cmt_cnt = cmt_cnt + 1
                else
                    if cmt_cnt > 0 then
                        new_line = new_line .. '-'
                        cmt_cnt = 0
                    end
                    new_line = new_line .. chr
                end

                -- if we are dealing with a lua comment (--) <- like this
                if cmt_cnt == 2 then
                    -- check for block comments
                    local v
                    v, b_cnt = is_block(line, i)
                    if v then
                        mode = "block"
                    else
                        break
                    end
                end
            elseif mode == "block" then
                -- return from a block comment
                if is_block_end(line, i, b_cnt) then
                    mode = "normal"
                end
            else
                print("This should be unreachable?")
            end
        end
        if #new_line > 0 then
            table.insert(new_lines, new_line)
        end
    end
    return new_lines
end

-- trim all lines in a source file
function trim_lines(lines)
    local new_lines = {}
    for _, line in ipairs(lines) do
        local trimmed = trim(line)
        if #trimmed > 0 then
            table.insert(new_lines, trimmed)
        end
    end
    return new_lines
end

function build_string(lines)
    local str = ""
    for i, line in ipairs(lines) do
        str = str .. line
        if i < #lines then
            str = str .. "\n"
        end
    end
    return str
end
-- END usage -------------------------------------------------------

-- Command Line Functions ------------------------------------------
function print_help()
    print("Jack The Stripper version 1")
    print("Usage:")
    print("\tjts.lua [OPTIONS] FILEPATH")
    print()
    print("Options:")
    print("\t-o FILE\t\tSpecify outfile name")
    print("\t-h\t\tPrint this help and exits")
end
-- END cmd ---------------------------------------------------------

-- Main!!! ------------------------------------------------------
function main()
    -- handle command line
    if #arg <= 0 then
        print("Not enough arguments")
        help_on = true 
    else
        local i = 1
        while i <= #arg do
            if arg[i] == "-h" then
                help_on = true
                i = i + 1
            elseif arg[i] == "-o" then
                out_path = arg[i+1]
                i = i + 2
            else
                path = arg[i]
                break
            end
        end
    end

    if not path and not help_on then
        print("No input file specified!")
        help_on = true
    end

    if not out_path then
        print("No output file specified!")
        help_on = true
    end

    if help_on then
        print_help()
        return
    end

    -- handle code stripping
    if not file_exist(path) then
        print("The file you want to strip doesn't exist!")
        return
    end
    local file = io.open(path, "r")
    local data = file:read("*a")
    file:close()
    
    local lines = handle_comments(trim_lines(split_and_cut(data)))

    data = build_string(lines)
    
    file = io.open(out_path, "w")
    file:write(data)
    file:close()
end

-- Calling main
main()