-- ---
-- Projeto: Gerenciador de Dotfiles Simples (DotManager)
-- Descrição: Uma ferramenta de linha de comando para gerenciar "dotfiles" (arquivos de configuração)
--            através da criação e remoção de links simbólicos para arquivos em um diretório central.
--            Este script assume que ele está no mesmo diretório que os seus dotfiles de origem.
-- Bibliotecas necessárias: luafilesystem
-- Instalação: luarocks install luafilesystem
-- Como executar:
--   lua main.lua status # Verifica o estado atual dos links
--   lua main.lua link   # Cria os links simbólicos para todos os arquivos configurados
--   lua main.lua unlink # Remove os links simbólicos criados
-- ---

-- Requer a biblioteca para manipulação do sistema de arquivos
local lfs = require("lfs")
local os = os
local io = io

-- --- CONFIGURAÇÃO ---
-- Mapeia o nome do arquivo de origem (neste diretório) para o seu destino (na home do usuário).
-- IMPORTANTE: Para segurança, os destinos são exemplos e não sobreescreverão seus arquivos reais.
-- Altere para os seus arquivos reais, como ".bashrc", quando estiver pronto.
local dotfiles_map = {
    { "bashrc.example", ".bashrc_from_lua" },
    { "vimrc.example", ".vimrc_from_lua" },
    { "gitconfig.example", ".gitconfig_from_lua" }
}

-- --- FUNÇÕES AUXILIARES ---

-- Função para obter o diretório home do usuário de forma portável
local function get_home_dir()
    return os.getenv("HOME") or os.getenv("USERPROFILE")
end

-- Função para imprimir mensagens coloridas no terminal (ANSI escape codes)
local function print_color(text, color)
    local colors = {
        green = "\27[32m",
        yellow = "\27[33m",
        red = "\27[31m",
        cyan = "\27[36m",
        reset = "\27[0m"
    }
    print(colors[color] .. text .. colors.reset)
end

-- --- LÓGICA PRINCIPAL DOS COMANDOS ---

-- Função para verificar o status dos dotfiles
function check_status()
    print_color("--- Verificando Status dos Dotfiles ---", "cyan")
    local home_dir = get_home_dir()
    local script_dir = lfs.currentdir()

    for _, file_map in ipairs(dotfiles_map) do
        local source_name = file_map[1]
        local dest_name = file_map[2]
        local source_path = script_dir .. "/" .. source_name
        local dest_path = home_dir .. "/" .. dest_name

        local dest_attr = lfs.attributes(dest_path)

        io.write(string.format("%-25s -> %s: ", source_name, dest_name))

        if not dest_attr then
            print_color("✗ NÃO ENCONTRADO", "yellow")
        elseif dest_attr.mode == "link" then
            local link_target = lfs.symlinkattributes(dest_path, "target")
            if link_target == source_path then
                print_color("✓ LINKADO CORRETAMENTE", "green")
            else
                print_color("✗ LINKADO PARA OUTRO LOCAL", "red")
            end
        else
            print_color("! ARQUIVO NORMAL EXISTE (NÃO É LINK)", "red")
        end
    end
end

-- Função para criar os links simbólicos
function link_files()
    print_color("--- Criando Links Simbólicos ---", "cyan")
    local home_dir = get_home_dir()
    local script_dir = lfs.currentdir()

    for _, file_map in ipairs(dotfiles_map) do
        local source_name = file_map[1]
        local dest_name = file_map[2]
        local source_path = script_dir .. "/" .. source_name
        local dest_path = home_dir .. "/" .. dest_name

        io.write(string.format("Ligando %s... ", dest_name))

        -- Verifica se o arquivo de origem existe
        if not lfs.attributes(source_path) then
            print_color("ERRO: Arquivo de origem não encontrado!", "red")
            goto continue
        end

        -- Verifica se o destino já existe
        if lfs.attributes(dest_path) then
            print_color("AVISO: Destino já existe, pulando.", "yellow")
            goto continue
        end

        -- Cria o link simbólico
        local ok, err = lfs.symlink(source_path, dest_path)
        if ok then
            print_color("✓ SUCESSO", "green")
        else
            print_color("✗ FALHA: " .. tostring(err), "red")
        end

        ::continue::
    end
end

-- Função para remover os links simbólicos
function unlink_files()
    print_color("--- Removendo Links Simbólicos ---", "cyan")
    local home_dir = get_home_dir()
    local script_dir = lfs.currentdir()

    for _, file_map in ipairs(dotfiles_map) do
        local source_name = file_map[1]
        local dest_name = file_map[2]
        local source_path = script_dir .. "/" .. source_name
        local dest_path = home_dir .. "/" .. dest_name

        io.write(string.format("Desligando %s... ", dest_name))

        local dest_attr = lfs.attributes(dest_path)

        if not dest_attr then
            print_color("AVISO: Já não existe, pulando.", "yellow")
        elseif dest_attr.mode == "link" and lfs.symlinkattributes(dest_path, "target") == source_path then
            -- Só remove se for um link simbólico apontando para nossa origem
            local ok, err = os.remove(dest_path)
            if ok then
                print_color("✓ REMOVIDO", "green")
            else
                print_color("✗ FALHA AO REMOVER: " .. tostring(err), "red")
            end
        else
            print_color("! NÃO É UM LINK GERENCIADO, PULAR MANUALMENTE", "red")
        end
    end
end

-- Função para mostrar as instruções de uso
function print_usage()
    print("Uso: lua main.lua <comando>")
    print("Comandos disponíveis:")
    print_color("  status", "cyan")
    print("    Verifica o estado atual dos links simbólicos.")
    print_color("  link", "cyan")
    print("    Cria os links simbólicos para os arquivos configurados.")
    print_color("  unlink", "cyan")
    print("    Remove os links simbólicos gerenciados por este script.")
end


-- --- PONTO DE ENTRADA DO SCRIPT ---
-- Captura o comando da linha de comando
local command = arg[1]

if command == "link" then
    link_files()
elseif command == "unlink" then
    unlink_files()
elseif command == "status" then
    check_status()
else
    print_usage()
end
