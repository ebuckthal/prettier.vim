local M = {};

formatprg = {
  html = 'prettier --no-color --parser html',
  yaml = 'prettier --no-color --parser yaml',
  json = 'prettier --no-color --parser json',
  markdown= 'prettier --no-color --parser markdown',
  javascript = 'prettier --no-color --parser babel',
  typescript = 'prettier --no-color --parser typescript',
  ['typescript.tsx'] = 'prettier --no-color --parser typescript'
}

-- https://github.com/norcalli/nvim_utils/blob/71919c2f05920ed2f9718b4c2e30f8dd5f167194/lua/nvim_utils.lua#L554-L567
local function nvim_create_augroups(definitions)
	for group_name, definition in pairs(definitions) do
		vim.api.nvim_command('augroup '..group_name)
		vim.api.nvim_command('autocmd!')
		for _, def in ipairs(definition) do
			-- if type(def) == 'table' and type(def[#def]) == 'function' then
			-- 	def[#def] = lua_callback(def[#def])
			-- end
			local command = table.concat(vim.tbl_flatten{'autocmd', def}, ' ')
			vim.api.nvim_command(command)
		end
		vim.api.nvim_command('augroup END')
	end
end

-- https://github.com/nanotee/nvim-lua-guide#vimapinvim_replace_termcodes
local function t(str)
    -- Adjust boolean arguments as needed
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end

-- preserves empty lines
function string:split(delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find(self, delimiter, from)
  while delim_from do
    table.insert(result, string.sub(self, from, delim_from-1))
    from  = delim_to + 1
    delim_from, delim_to = string.find(self, delimiter, from)
  end
  table.insert(result, string.sub(self, from))
  return result
end

M.init = function ()
  local autocmds = {
    prettier = {
      {"BufWritePre", "*.js,*.jsx,*.ts,*tsx,*.json,*.gql,*.md,*.html", [[lua require('prettier').prettier()]]};
    };
  }

  nvim_create_augroups(autocmds)
end


M.prettier = function ()

  if 0 == vim.fn.executable('prettier') then
    print('prettier failed! No executable detected')
    return
  end


  local view = vim.fn.winsaveview();
  local stdin = vim.fn.getbufline(vim.fn.bufnr("%"), 1, "$")

  local stdout = vim.fn.system(formatprg[vim.bo.filetype], stdin);
  local sherror = vim.api.nvim_get_vvar('shell_error')

  if sherror == 2 then 
    -- Populate errors into qflist
    local errors = {}

    for line in string.gmatch(stdout, "[^\r\n]+") do
      -- matches '([line]:[col])' in output
      lnum, col = string.match(line, "(%d+):(%d+)")
      if lnum then
        table.insert(errors, { 
          bufnr = vim.fn.bufnr("%"), 
          text = line, 
          lnum = tonumber(lnum), 
          col = tonumber(col) }
        )
      end
    end

    if #errors == 0 then 
      -- incase we don't parse anything, yell
      print(stdout)
    else 
      vim.fn.setqflist(errors, " ")
    end

    vim.cmd("botright copen")

  else 
    -- Lifted from the "official" vim-prettier plugin
    -- Keeping cursor position + undo history is not simple--glad they figured it out
    -- https://github.com/prettier/vim-prettier/blob/aa0607ca7a0f61e91365ecf25947312ff4796302/autoload/prettier/utils/buffer.vim#L13

    -- create a fake change entry and merge with undo stack prior to do formating
    vim.cmd('normal! a')
    vim.cmd(t'normal! a<BS>')
    vim.cmd('try | silent undojoin | catch | endtry')

    --delete all lines on the current buffer
    vim.cmd('lockmarks %delete _')

    -- get buffer as lines
    local stdout_lines = stdout:split("\n")

    -- set it as output from command
    vim.fn.setline(1, stdout_lines)

    -- delete trailing newline introduced by the above append procedure
    vim.cmd('lockmarks $delete _')

    -- Remove entries from quickfixlist and close it
    vim.fn.setqflist({}, " ")
    vim.cmd("cclose")
  end
  
  vim.fn.winrestview(view)
end

return M


