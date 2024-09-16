// import Forest

// extension Branch 
// {
//     @propertyWrapper
//     struct Field<Value>:Sendable where Value:Equatable
//     {
//         private 
//         var bits:UInt32
        
//         init()
//         {
//             self.bits = .max
//         }
        
//         var wrappedValue:Head<Value>?
//         {
//             get 
//             {
//                 self.bits != .max ? .init(.init(bits: self.bits)) : nil
//             }
//             set(value)
//             {
//                 if let bits:UInt32 = value?.index.bits
//                 {
//                     precondition(bits != .max)
//                     self.bits = bits 
//                 }
//                 else 
//                 {
//                     self.bits = .max
//                 }
//             }
//         }
//     }
// }