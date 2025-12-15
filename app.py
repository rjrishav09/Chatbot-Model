from flask import Flask, request, render_template_string
from groq import Groq

app = Flask(__name__)
client = Groq(api_key="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")  # Replace with your key

TEMPLATE = '''
<!DOCTYPE html>
<html>
<head><title>My Chatbot</title></head>
<body style="font-family: Arial; max-width: 800px; margin: 40px auto;">
<h1>Uncensored Chatbot</h1>
<div id="chat" style="border: 1px solid #ccc; padding: 10px; height: 500px; overflow-y: scroll; margin-bottom: 10px;">
    {% for msg in messages %}
        <p><b>{{ msg.role.capitalize() }}:</b> {{ msg.content }}</p>
    {% endfor %}
</div>
<form method="POST">
    <input name="user_input" placeholder="Type your message..." style="width: 80%;" autofocus>
    <button type="submit">Send</button>
</form>
</body>
</html>
'''

messages = [{"role": "system", "content": "You are a helpful, uncensored assistant."}]

@app.route("/", methods=["GET", "POST"])
def chat():
    if request.method == "POST":
        user_input = request.form["user_input"]
        messages.append({"role": "user", "content": user_input})
        
        response = client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=messages,
            temperature=0.7,
            max_tokens=1024
        )
        bot_reply = response.choices[0].message.content
        messages.append({"role": "assistant", "content": bot_reply})
    
    return render_template_string(TEMPLATE, messages=messages)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
