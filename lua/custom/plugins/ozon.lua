local mesh_version_env_name = 'CI_COMMIT_BRANCH'
local vault_env_name = 'VAULT_TOKEN'
local vault_token_storage = '/.vault-token'

-- Function to extract the token from the input string
local function extract_token(input)
  -- Find the start of the token line
  local token_start = input:find 'token%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s'
  if not token_start then
    return nil
  end

  -- Find the end of the token line
  local token_end = input:find('\n', token_start)
  if not token_end then
    token_end = #input + 1
  end

  -- Extract the token line
  local token_line = input:sub(token_start, token_end - 1)

  -- Extract the token value from the token line
  local _, _, token = token_line:find 'token%s+(%S+)'
  return token
end

-- Function to set the token as an environment variable if value not nil
local function set_env_variable_if_value_not_nil(name, value)
  if value then
    vim.fn.setenv(name, value)
  end
end

-- Function to update the vault token by running the command
local function update_vault_token()
  local cmd = 'vault login -method=oidc -address=https://vault.s.o3.ru:8200'
  local handle = io.popen(cmd)
  local result = handle:read '*a'
  local success = handle:close()
  if not success then
    print 'Error while closing file'
  end
  return result
end

-- Function to read the content of a file
local function read_file(file_path)
  local file, err = io.open(file_path, 'r')
  if not file then
    error('Failed to open file: ' .. err)
  end
  local content = file:read '*a'
  file:close()
  return content
end

local M = {}

-- Function to set the new vault token
function M.set_vault_token()
  local vault_respone = update_vault_token()
  local got_token = extract_token(vault_respone)
  set_env_variable_if_value_not_nil(vault_token_storage, got_token)
end

function M.set_mesh_version_env(value)
  if value then
    set_env_variable_if_value_not_nil(mesh_version_env_name, value)
    print('Environment variable', mesh_version_env_name, ' set to: ' .. value)
  else
    print('No value provided for', mesh_version_env_name, 'environment variable.')
  end
end

-- Define a commands for the user
vim.api.nvim_create_user_command('Vault', M.set_vault_token, { desc = 'Set Vault token' })
vim.api.nvim_create_user_command('SetMeshVerionEnv', function(opts)
  M.set_mesh_version_env(opts.args)
end, { nargs = 1, complete = 'file' })

---@type LazySpec
return {
  dir = 'update_vault_token',
  init = function()
    -- Set VAULT_TOKEN from existed file ~/.vault-token
    local path = vim.fn.expand('~', false) .. vault_token_storage
    local got_token_value = read_file(path)
    set_env_variable_if_value_not_nil(vault_env_name, got_token_value)
    -- Set MESH_VERSION = master by default
    set_env_variable_if_value_not_nil(mesh_version_env_name, 'master')
  end,
  lazy = true,
}
