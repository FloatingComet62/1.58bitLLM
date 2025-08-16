from random import random

NUMBER_OF_ITEMS = 10000
NUMBER_OF_INPUTS = 5
NUMBER_OF_OUTPUTS = 5

file = open("src/training_data.txt", "w")
file.write(f"{NUMBER_OF_INPUTS}|{NUMBER_OF_OUTPUTS}\n")


def f(input):
    assert len(input) == NUMBER_OF_INPUTS, f"""
Expected input length to be {NUMBER_OF_INPUTS}, but it is {len(input)}
The input was {input}
""".strip()
    return input[::-1]


for _ in range(NUMBER_OF_ITEMS):
    input = [random() * 10 for _ in [0] * NUMBER_OF_INPUTS]
    output = f(input)
    assert len(output) == NUMBER_OF_OUTPUTS, f"""
Expected output length to be {NUMBER_OF_OUTPUTS}, but it is {len(output)}
The input was {input}
The output was {output}
""".strip()

    file.write(
        " ".join(map(str, input)) + "|" + " ".join(map(str, output)) + "\n"
    )

file.close()
