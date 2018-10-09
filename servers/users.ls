require! 'dcs/src/auth-helpers': {hash-passwd}
export users =
    'public':
        passwd-hash: hash-passwd "public"
        routes:
            \@mydevice.hello.**
        permissions:
            'something'
            'something-else'

    'mydevice':
        passwd-hash: hash-passwd "1234"

    'myuser':
        passwd-hash: hash-passwd "5678"
        groups:
            \public  # inherit all routes and permissions from public user
        routes:
            \@mydevice.foo.**
        permissions:
            \slider2.write

    'hellouser':
        passwd-hash: hash-passwd "1234"
        permissions:
            \scene.hello.**
