!/bin/bash

echo "in another terminal, run tail -f errors"
python mazegen.py 2> errors
