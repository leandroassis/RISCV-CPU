lista = ['0000011']

with open("./truth_table.txt", "w") as f:
    for i in range(128):
        numero = '{0:07b}'.format(i)
        print(numero, numero in lista)
        if numero in lista:
            f.write("1 ")
            continue
        f.write("0 ")