import SwiftUI

public extension Observable where Self: AnyObject {
    var bindable: Bindable<Self> {
        Bindable(self)
    }
}
