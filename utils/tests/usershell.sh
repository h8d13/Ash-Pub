doas su - username -c 'export DISPLAY=:0; export XDG_RUNTIME_DIR=/run/user/$(id -u); command_to_run'
