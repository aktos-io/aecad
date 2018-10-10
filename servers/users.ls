require! 'dcs/src/auth-helpers': {hash-passwd}
export users =
    'public':
        passwd-hash: hash-passwd "public"
        routes:
            \@occ-worker.**

    'occ-worker':
        passwd-hash: hash-passwd "1234"
