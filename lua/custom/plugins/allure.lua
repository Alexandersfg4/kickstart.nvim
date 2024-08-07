local job_id = nil

-- Run a command in a specified directory
local function run_command(command, cwd)
  job_id = vim.fn.jobstart(command, {
    cwd = cwd,
    on_exit = function(job_id, exit_code, event)
      if exit_code ~= 0 then
        print('Command failed with exit code ' .. exit_code)
      else
        print 'Command executed successfully'
      end
      job_id = nil
    end,
  })
end

local M = {}
M.tag = 'e2e' -- Default tag

-- Check and run AllureServe
function M.check_and_run_allure()
  if job_id ~= nil then
    print 'A command is already running. Please wait or press <C-c> to stop it.'
    return
  end

  local project_root = vim.fn.getcwd()
  local allure_results_path = project_root .. '/allure-results'
  local test_dir_path = project_root .. '/test/tests'

  if vim.fn.isdirectory(allure_results_path) == 1 then
    run_command('allure serve', project_root)
  elseif vim.fn.isdirectory(test_dir_path) == 1 then
    run_command('allure serve', test_dir_path)
  else
    print 'Neither allure-results nor test/tests directory found in the project.'
  end
end

-- Stop the currently running command
function M.stop_allure()
  if job_id ~= nil then
    vim.fn.jobstop(job_id)
    job_id = nil
    print 'Command stopped.'
  else
    print 'No command is currently running.'
  end
end

-- Run a specific Go test based on the cursor position
function M.run_go_test()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  local line = vim.api.nvim_get_current_line()

  local left_part = line:sub(1, col):match '[%w_]+$' or ''
  local right_part = line:sub(col + 1):match '^[%w_]+' or ''
  local word = left_part .. right_part

  local command = string.format('go test ./test/tests -tags %s --allure-go.m %s', M.tag, word)
  vim.cmd('terminal ' .. command)
end

-- Run all Go tests
function M.run_go_test_all()
  local command = string.format('go test ./test/tests -tags %s', M.tag)
  vim.cmd('terminal ' .. command)
end

-- Change the tag used for Go tests
function M.change_tag()
  local prompt = 'Enter new tag: '
  local new_tag = vim.fn.input(prompt)
  if new_tag and #new_tag > 0 then
    M.tag = new_tag
    print('\nTag changed to: ' .. new_tag)
  else
    print 'Tag change aborted.'
  end
end

-- Define user commands for the plugin
vim.api.nvim_create_user_command('AllureServe', M.check_and_run_allure, { desc = 'Run AllureServe' })
vim.api.nvim_create_user_command('AllureStop', M.stop_allure, { desc = 'Stop AllureServe' })
vim.api.nvim_create_user_command('AllureTestFunc', M.run_go_test, { desc = 'Run test under cursor' })
vim.api.nvim_create_user_command('AllureTestAll', M.run_go_test_all, { desc = 'Run all tests' })
vim.api.nvim_create_user_command('AllureChangeTag', M.change_tag, { desc = 'Change tag' })

-- Map keybindings to trigger the functions
vim.api.nvim_set_keymap('n', '<leader>ar', '<Cmd>AllureServe<CR>', { noremap = true, silent = true, desc = 'Run AllureServe' })
vim.api.nvim_set_keymap('n', '<leader>as', '<Cmd>AllureStop<CR>', { noremap = true, silent = true, desc = 'Stop AllureServe' })
vim.api.nvim_set_keymap('n', '<leader>af', '<Cmd>AllureTestFunc<CR>', { noremap = true, silent = true, desc = 'Run test under cursor' })
vim.api.nvim_set_keymap('n', '<leader>at', '<Cmd>AllureTestAll<CR>', { noremap = true, silent = true, desc = 'Run all tests' })
vim.api.nvim_set_keymap('n', '<leader>ac', '<Cmd>AllureChangeTag<CR>', { noremap = true, silent = true, desc = 'Change tag' })

return {
  dir = 'allure',
  name = 'Allure',
  desc = 'Allure tools',
  lazy = true,
}
