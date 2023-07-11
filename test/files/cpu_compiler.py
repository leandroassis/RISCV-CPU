def translate(instrucao: list) -> str:
    print(instrucao)

with open("code.S", "r") as f:
    code = f.readlines()
    f.close()

bin_instruc = []
for instrucao in code:
    bin_instruc.append(translate(instrucao.split()))
