# GIT COMMANDS





## Enviando alterações e/ou novo <branch>
- **NORMAL:** ```git push origin <branch>```
- **REBASE:** ```git push --force origin <branch>```

## Actualizar o repositorio com a versão mais recente remoto
- **NORMAL:** ```git pull```
- **REBASE:**
    1. ``` git fetch origin ```
    2. ``` git reset --hard origin/<branch> ```

## Merge/Log/Tag/Diferenças e Estado actual
- **MERGE:**
    + **NOMAL:**
        1. Mudar para a \<branch>
        2. ```git merge <branch_1>```
    + **REBASE:**
        1. Mudar para a \<branch>
        2. ```git rebase origin/<branch_1>```
- **LOG:** ```git log```
- **TAG:**
    1. Localizar o ID_LOG
    2. ```git tag 1.0.0 ID_LOG```     (1.0.0 - Versão)
- **ESTADO_ACTUAL:** ```git status```
- **DIFF:** ```git diff <branch origem> <branch destino>``` (*Mostra as diferenças entre origem e destino*)

## Rebase iterativo
1. Localizar o ID_LOG (*Normalmente pegar o 3º ID_LOG a contar do ultimo commit*)
2. ```git rebase -i ID_LOG``` (*f = fix up. Mudar para a linha logo a seguir da linha do commit que quer e mudar para f antes do comentario do commit*)

## CONFIG MERGE/DIFF TOOL APP
- **MERGE:**
    1. ```git config --global merge.tool <NAMETOOL>```
    2. ```git config --global mergetool.<NAMETOOL>.path <FULL_PATH_EXECUTABLE_APP>```
    3. ```git config --global mergetool.<NAMETOOL>.cmd <COMMAND_TO_EXECUTE_APP>```
- **DIFF:**
    1. ```git config --global diff.tool <NAMETOOL>```
    2. ```git config --global difftool.<NAMETOOL>.path <FULL_PATH_EXECUTABLE_APP>```
    3. ```git config --global difftool.<NAMETOOL>.cmd <COMMAND_TO_EXECUTE_APP>``` (*EXEMPLE WIN: ```"C:/Program Files/KDiff3/kdiff3.exe" "$LOCAL" "$REMOTE"```*)

## Guardar as alterações sem adicionar ao index
1. ```git stash``` (Guarda)
2. ```git stash pop``` (Restaura)

## Submodulos
- **ADD:** ```git submodule add <url_repository> <path_for_submodulo>```
- **USING:**
    1. ```git submodule init```
    2. ```git submodule update```
- **DELETE:**
    1. ```git submodule rm <path_for_submodulo>```
    2. ```git rm --cached <path_for_submodulo>```

    git submodule deinit <path_to_submodule>
git rm <path_to_submodule>
git commit-m "Removed submodule "
rm -rf .git/modules/<path_to_submodule>

## OUTROS
- **SET NAME|EMAIL:** ```git config [--global] user.name|user.email <name|email>```
- **GET CONFIG:** ```git config --list [--global|--local]```

## Gerar SSH Key
- **WSL**:
    1. ```mkdir /mnt/c/Users/<username>/.ssh```
    2. ```ln -s /mnt/c/Users/<username>/.ssh ~/.ssh```
    3. ```ssh-keygen -t rsa -C "your_email@example.com"```
    4. Chave para o GIT: ```cat ~/.ssh/id_rsa.pub```
- **Outros:** Os mesmos pontos que o *WSL* excepto os pontos *1* e *2*
