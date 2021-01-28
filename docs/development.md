> Following instructions are tested on a clean LXC container, created by:
>
>     sudo lxc-create -n aecad -t debian -B btrfs -- -r buster --packages nano sudo tmux git
>

## Requriements

* git
* tmux
* python-pip
* bash-completion (recommended)

## Preparation

1. Install `nodeenv`: 

       pip install nodeenv  # don't forget to add ~/.local/bin to your $PATH

2. Clone this repository. Assuming you are at `~/some/path`:

       git clone --recursive https://github.com/aktos-io/aecad
       cd aecad

3. Create your virtual environment:[¹](https://github.com/aktos-io/scada.js/blob/master/doc/using-virtual-environment.md): 

    > For Windows platform, follow [these instructions](https://github.com/aktos-io/scada.js/tree/master/doc/on-windows) first.

    ```console
    $ cd ./scada.js
    $ make create-venv
    $ ./venv  
    (scadajs1) $ exit 
    ````

4. Install required packages: 

    ```console
    $ cd ..   # now you are in ~/some/path/aecad
    $ make install-deps
    ```

5. Open 2 different terminals and run those commands in each of them (or skip this step completely and proceed to `#6`): 

    Terminal-1:
    ```console
    $ ./scada.js/venv
    (scadajs1) $ (cd scada.js && APP=main make development)
    ```

    Terminal-2:
    ```console
    $ ./scada.js/venv
    (scadajs1) $ (cd servers && ./run-ls webserver.ls --development)
    ```

#### 6. (Optional) Use `tmux`:

1. Add the following code to the `~/.bashrc`:

    ```sh
    # For Tmux VirtualEnv support
    tmux_get_var(){
        local key=$1
        [[ -n "$TMUX" ]] && tmux showenv | awk -F= -v key="$key" '$1==key {print $2}'
    }

    # activate the virtual environment if it is declared
    venv=$(tmux_get_var "VIRTUAL_ENV")
    if [ -n "$venv" ]; then
        OLD="$PATH"
        source $venv/bin/activate;
        export PATH="$PATH:$OLD"
    fi
    ```

2. Start the development anytime by: 

    ```sh
    ./uidev.service`
    ```

#### 7. Navigate to http://localhost:4001
