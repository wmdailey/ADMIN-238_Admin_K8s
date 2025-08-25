import sys

# The script's standard input is the client's output, and
# its standard output is sent back to the client.
sys.stdout.write("Hello from the Python socat server!\n")

# A small loop to keep the connection alive until the client closes it.
# This allows for a conversational back-and-forth.
while True:
    try:
        line = sys.stdin.readline()
        if not line:
            break
        sys.stdout.write(f"You said: {line.strip()}\n")
        sys.stdout.flush()
    except:
        break
