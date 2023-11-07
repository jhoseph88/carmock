//
//  main.swift
//  CarMock
//
//  Created by Cameron Barnes on 10/1/23.
//

import Foundation
import CoreBluetooth

/**
 Write a string to the specified file handle.
 
 - Parameters:
    - fileHandle: The target file handle, eg. `STDERR`.
    - message:    The string to be written.
 */
func writeOut(_ fileHandle: FileHandle, _ message: String) {

    let outputString: String = message + "\r\n"
    if let outputData: Data = outputString.data(using: .utf8) {
        fileHandle.write(outputData)
    }
}

/**
 Write result data and app output to `stdout`.
 
 - Parameters:
    - output: The string to output.
 */
func writeToStdout(_ output: String) {
    writeOut(FileHandle.standardOutput, output)
}

/**
 Display the app's help information.
 */
func showHelp() {
    let BOLD: String                = "\u{001B}[1m"
    let RESET: String               = "\u{001B}[0m"
    writeToStdout(BOLD + "USAGE" + RESET + "\n    ./carmock ERROR_1 ERROR_2 ... ERROR_N")
}

class CarMockPeripheral: NSObject, CBPeripheralManagerDelegate, CBPeripheralDelegate {
    private var peripheralManager: CBPeripheralManager!
    
    let advertisementDataLocalNameKey: String = "max8Chars"
    var DTCs: [String] = []
    var dtcService: CBMutableService
    var pendingUpdateVal: [UInt8] = Array("ATZ\r".utf8);
    let ELM_MAP: [String: [[UInt8]]] = [
        "ATZ\rATE0\r\r\r\r\r\r\r\r\r": [Array("ATZ\r".utf8), Array("\r\rELM327 v1.5\r\r>".utf8)],
        "\r\r": [Array("\r".utf8), Array("?\r\r>".utf8)],
        "ATE0\r": [Array("ATE0\r".utf8), Array("OK\r\r>".utf8)],
        "STI\r": [Array("?\r\r>".utf8)],
        "VTI\r": [Array("?\r\r>".utf8)],
        "ATD\r": [Array("OK\r\r>".utf8)],
        "ATD0\r": [Array("OK\r\r>".utf8)],
        "ATSP0\r": [Array("OK\r\r>".utf8)],
        "ATH1\r": [Array("OK\r\r>".utf8)],
        "ATM0\r": [Array("OK\r\r>".utf8)],
        "ATS6\r": [Array("?\r\r>".utf8)],
        "ATS0\r": [Array("OK\r\r>".utf8)],
        "ATAT1\r": [Array("OK\r\r>".utf8)],
        "ATAL\r": [Array("OK\r\r>".utf8)],
        "ATST34\r": [Array("OK\r\r>".utf8)],
        "ATST32\r": [Array("OK\r\r>".utf8)],
        "ATST96\r": [Array("OK\r\r>".utf8)],
        "0100\r": [Array("7E8 06 41 00 BE 3E A8 13 \r".utf8),  Array("\r>".utf8)],
        "0120\r": [Array("7E8 06 41 20 80 05 B0 11 \r".utf8),  Array("\r>".utf8)],
        "0140\r": [Array("7E8 06 41 40 FE D0 84 00 \r".utf8),  Array("\r>".utf8)],
        "0902\r": [Array("7E8 10 14 49 02 01 57 56 57 \r7E8 21 41 41 37 41 4A 31 43 \r7E8 22 57 32 39 30 37 35 33 \r".utf8), Array("\r>".utf8)],
        "0904\r": [Array("7E8 10 13 49 04 01 30 37 4B \r7E8 21 39 30 36 30 35 35 44 \r7E8 22 47 20 34 37 34 30 00 \r".utf8), Array("\r>".utf8)],
        "ATDPN\r": [Array("A6\r\r>".utf8)],
        "ATSP6\r": [Array("OK\r\r>".utf8)],
        "ATSP7\r": [Array("OK\r\r>".utf8), Array(">".utf8)],
    ]
    
    required override init() {
        let serviceUUID: CBUUID = CBUUID(string: "4F9289BC-7CCE-45B4-AD12-4D142BF62C28")
        dtcService = CBMutableService(type: serviceUUID, primary: true)
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionRestoreIdentifierKey: "com.fugueai.CarMock.peripheral"])
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch self.peripheralManager.state {
        case .poweredOn:
            print("Peripheral poweredOn")
        
            
            let characteristicUUID = CBUUID(string: "F411CC51-B103-412F-B503-6A2432B5B7AE")
            let mutableCharacteristic: CBMutableCharacteristic = CBMutableCharacteristic(type: characteristicUUID, properties: [.write, .read, .notify], value: nil, permissions: [.writeable, .readable])
            self.dtcService.characteristics = [mutableCharacteristic]
            
            self.peripheralManager.add(dtcService)
            self.peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [self.dtcService.uuid], CBAdvertisementDataLocalNameKey: advertisementDataLocalNameKey])
        case .poweredOff:
            print("Peripheral poweredOff")
        case .resetting:
            print("Peripheral resetting")
        case .unauthorized:
            print("Peripheral unauthorized")
        case .unknown:
            print("Peripheral unknown")
        case .unsupported:
            print("Peripherel unsupported")
        @unknown default:
            print("Peripheral unknown")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        var arr: [UInt8] = Array(self.DTCs[0].utf8)
        let mockDTC: Data = Data(bytes: &arr, count: arr.count)
        request.value = mockDTC
        self.peripheralManager.respond(to: request, withResult: .success)
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        let dtcCharacteristic: CBMutableCharacteristic = self.dtcService.characteristics?.first as! CBMutableCharacteristic
        peripheralManager.updateValue(Data(bytes: self.pendingUpdateVal, count: self.pendingUpdateVal.count), for: dtcCharacteristic, onSubscribedCentrals: nil)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        if let request = requests.first {
            if let value = request.value {
                let valueBytes: [UInt8] = [UInt8](value)
                let dtcCharacteristic: CBMutableCharacteristic = self.dtcService.characteristics?.first as! CBMutableCharacteristic
                let reqString = String(bytes: valueBytes, encoding: String.Encoding.utf8)
                print("Decoded data received: \(reqString)")
                let valsToUpdate = self.ELM_MAP[reqString!]!
                
                for updatedVal in valsToUpdate {
                    // Return each updated value after waiting 3 sec
                    let seconds = 2.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                        self.pendingUpdateVal = updatedVal
                        self.peripheralManager.updateValue(Data(bytes: updatedVal, count: updatedVal.count), for: dtcCharacteristic, onSubscribedCentrals: nil)
                    }
                }
                self.peripheralManager.respond(to: request, withResult: .success)
            }
        }
    }
}

// Set up an event source for SIGINT...
//let dss: DispatchSourceSignal = DispatchSource.makeSignalSource(signal: SIGINT,
//                                                                queue: DispatchQueue.main)
var args: [String] = CommandLine.arguments
//if args.count == 1 {
//    showHelp()
//    dss.cancel()
//    exit(EXIT_SUCCESS)
//}


let codes = Array(args[1..<args.count])

let peripheral = CarMockPeripheral()
peripheral.DTCs = codes


while true && RunLoop.current.run(mode: RunLoop.Mode.default, before: Date.distantFuture) {
     
}
