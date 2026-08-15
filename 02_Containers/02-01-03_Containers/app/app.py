from flask import Flask, render_template

# Initialize the Flask application
app = Flask(__name__)

# Route for the home page
@app.route('/')
def index():
    # It's conventional to name the function after the route, like 'index' for '/'
    return render_template('index.html')

# Standard way to run the application
if __name__ == '__main__':
    # Using '0.0.0.0' makes the server externally visible, useful in containers/VMs.
    # Defining the port as an integer is cleaner.
    # debug=True is great for development.
    app.run(host='0.0.0.0', port=3000, debug=True)
