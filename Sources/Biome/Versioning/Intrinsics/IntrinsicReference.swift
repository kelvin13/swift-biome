protocol IntrinsicDivergenceBase:BranchDivergenceBase
{
    init()
}

protocol IntrinsicReference:AtomicReference 
{
    associatedtype Group
    associatedtype Offset:UnsignedInteger where Offset.Stride == Int

    associatedtype Intrinsic:Identifiable
    associatedtype Divergence:BranchDivergence<Self> 
        where Divergence.Base:IntrinsicDivergenceBase
    
    init(_:Group, offset:Offset)
    var offset:Offset { get }
}

extension IntrinsicReference
{
    func positioned(
        bisecting trunk:some RandomAccessCollection<Period<IntrinsicSlice<Self>>>) 
        -> AtomicPosition<Self>?
    {
        let period:Period<IntrinsicSlice<Self>>? = trunk.search 
        {
            if      self.offset < $0.axis.indices.lowerBound 
            {
                return .lower 
            }
            else if self.offset < $0.axis.indices.upperBound 
            {
                return nil 
            }
            else 
            {
                return .upper
            }
        }
        return (period?.branch).map(self.positioned(_:))
    }
}

private
enum BinarySearchPartition 
{
    case lower 
    case upper
}
private 
extension RandomAccessCollection 
{
    func search(by partition:(Element) throws -> BinarySearchPartition?) rethrows -> Element?
    {
        var count:Int = self.count
        var current:Index = self.startIndex
        
        while 0 < count
        {
            let half:Int = count >> 1
            let median:Index = self.index(current, offsetBy: half)

            let element:Element = self[median]
            switch try partition(element)
            {
            case .lower?:
                count = half
            case nil: 
                return element
            case .upper?:
                current = self.index(after: median)
                count -= half + 1
            }
        }
        return nil
    }
}