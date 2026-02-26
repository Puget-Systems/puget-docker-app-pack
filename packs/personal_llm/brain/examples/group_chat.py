import autogen

# Configuration to connect to the local Ollama instance
config_list = [
    {
        "model": "llama3.2", # Make sure this model is pulled!
        "base_url": "http://inference:11434/v1",
        "api_key": "ollama",
    }
]

# 1. The Manager (User Proxy)
# This agent acts as the bridge between the user and the swarm.
user_proxy = autogen.UserProxyAgent(
    name="User_Proxy",
    system_message="A human admin.",
    code_execution_config={"work_dir": "groupchat"},
    human_input_mode="TERMINATE",
)

# 2. The Expert (Writer/Planner)
writer = autogen.AssistantAgent(
    name="Writer",
    system_message="You are a skilled technical writer. You plan and draft documentation.",
    llm_config={"config_list": config_list},
)

# 3. The Critic (Reviewer)
critic = autogen.AssistantAgent(
    name="Critic",
    system_message="You verify the content for accuracy and conciseness.",
    llm_config={"config_list": config_list},
)

# Create the Group Chat
groupchat = autogen.GroupChat(
    agents=[user_proxy, writer, critic], messages=[], max_round=12
)
manager = autogen.GroupChatManager(groupchat=groupchat, llm_config={"config_list": config_list})

# Start the chat
user_proxy.initiate_chat(
    manager, message="Write a short summary of why open source local LLMs are the future."
)
