from flask import Flask, render_template

app = Flask(__name__)

@app.route('/')
def run():
    return render_template('index.html')

if __name__ == '__main__':
     app.run(host='0.0.0.0', port=int("3000"), debug=True)
