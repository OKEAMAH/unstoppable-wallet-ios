import RxCocoa
import RxRelay
import RxSwift

class SendTimeLockErrorService {
    private let disposeBag = DisposeBag()

    private let timeLockService: TimeLockService
    private let addressService: AddressService
    private let adapter: ISendBitcoinAdapter

    private let errorRelay = BehaviorRelay<Error?>(value: nil)
    private(set) var error: Error? {
        didSet {
            errorRelay.accept(error)
        }
    }

    init(timeLockService: TimeLockService, addressService: AddressService, adapter: ISendBitcoinAdapter) {
        self.timeLockService = timeLockService
        self.addressService = addressService
        self.adapter = adapter

        subscribe(disposeBag, timeLockService.pluginDataObservable) { [weak self] _ in
            self?.sync()
        }
        subscribe(disposeBag, addressService.stateObservable) { [weak self] _ in
            self?.sync()
        }
    }

    private func sync() {
        guard !timeLockService.pluginData.isEmpty,
              let address = addressService.state.address
        else {
            error = nil
            return
        }

        do {
            _ = try adapter.validate(address: address.raw, pluginData: timeLockService.pluginData)
            error = nil
        } catch {
            self.error = error.convertedError
        }
    }
}

extension SendTimeLockErrorService: IErrorService {
    var errorObservable: Observable<Error?> {
        errorRelay.asObservable()
    }
}
