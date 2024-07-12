def generate_env_example(env_filename, example_filename):
    try:
        with open(env_filename, 'r') as file:
            lines = file.readlines()

        with open(example_filename, 'w') as example_file:
            for line in lines:
                if '=' in line:
                    key = line.split('=')[0]
                    example_file.write(f"{key}=\n")
    except Exception as e:
        print(f"An error occurred: {e}")

# File paths relative to the script location or provide absolute paths
env_filename = '../.env'
example_filename = '../.env.example'

generate_env_example(env_filename, example_filename)
