import serial
print(serial.__file__)
import time

def main():
    # Abra a porta COM8 com taxa de 115200 baud e timeout de 1 segundo
    ser = serial.Serial('COM10', 115200, timeout=5)
    
    # Aguarda alguns segundos para estabilizar a conexão
    time.sleep(2)
    while True:
        print("Aguardando dados na porta serial...")
        # Loop até receber algum dado
        while True:
            if ser.in_waiting:
                dados = ser.read(ser.in_waiting)
                print("Dado recebido:", dados)
                break
            time.sleep(0.1)
        
        # Depois de receber o dado, aguarda 5 segundos e envia o byte 0x01
        print("Recebeu dados. Aguardando 5 segundos antes de enviar o byte...")
        time.sleep(5)
        ser.write(b'\x01')
        print("Enviado o byte: 0x01")

if __name__ == "__main__":
    main()
