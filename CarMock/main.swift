//
//  main.swift
//  CarMock
//
//  Created by Cameron Barnes on 10/1/23.
//

import Foundation
import CoreBluetooth

class CarMockPeripheral: NSObject, CBPeripheralManagerDelegate, CBPeripheralDelegate {
    private var peripheralManager: CBPeripheralManager!
    
    let advertisementDataLocalNameKey: String = "max8Chars"
    var DTC: String = ""
    var dtcService: CBMutableService
    
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
            let mutableCharacteristic: CBMutableCharacteristic = CBMutableCharacteristic(type: characteristicUUID, properties: [.write, .read], value: nil, permissions: [.writeable, .readable])
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
        self.peripheralManager.respond(to: request, withResult: .success)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        if let request = requests.first {
            if let value = request.value {
                let valueBytes: [UInt8] = [UInt8](value)
                print("Received data: \(valueBytes)")

                let dtcCharacteristic: CBMutableCharacteristic = self.dtcService.characteristics?.first as! CBMutableCharacteristic
                var arr: [UInt8] = Array(self.DTC.utf8)
                let mockDTC: Data = Data(bytes: &arr, count: arr.count)
                self.peripheralManager.updateValue(mockDTC, for: dtcCharacteristic, onSubscribedCentrals: nil)
            }
        }
    }
}

let code = CommandLine.arguments[0]

let peripheral = CarMockPeripheral()
peripheral.DTC = code


while true && RunLoop.current.run(mode: RunLoop.Mode.default, before: Date.distantFuture) {
     
}
