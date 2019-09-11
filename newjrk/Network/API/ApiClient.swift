import UIKit

class ApiClient {
    enum ApiError: Error {
        case noRootDocument
        case decodingError
    }

    // MARK: - Internal properties

    var streamName: String? {
        rootDocument?.streamName
    }

    var playlistURL: URL? {
        guard let path = rootDocument?.playlist else { return nil }
        return networkClient.rootURL.appendingPathComponent(path)
    }

    // MARK: - Private properties

    private let networkClient: NetworkClientProtocol
    private var rootDocument: RootDTO?

    // MARK: - Init

    init(networkClient: NetworkClientProtocol, initCompletionHandler: @escaping ((Error?) -> Void)) {
        self.networkClient = networkClient
        loadRootDocument { error in
            initCompletionHandler(error)
        }
    }

    /// - Note: This constructor does **NOT** load the root document
    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    // MARK: - Internal methods

    func loadRootDocument(completion: @escaping (Error?) -> Void) {
        networkClient.get("/", resultHandler: { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    guard let rootDoc = RootDTO.decoded(fromJson: data) else {
                        completion(ApiError.decodingError)
                        return
                    }
                    self?.rootDocument = rootDoc
                    completion(nil)
                case .failure(let error):
                    completion(error)
                }
            }
        })
    }

    func loadStreamPicture(completion: @escaping (Result<UIImage,Error>) -> Void) {
        guard let path = rootDocument?.streamPicture else {
            DispatchQueue.main.async {
                completion(.failure(ApiError.noRootDocument))
            }
            return
        }

        networkClient.get(path, resultHandler: { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    guard let image = UIImage(data: data) else {
                        completion(.failure(ApiError.decodingError))
                        return
                    }
                    completion(.success(image))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        })
    }
}
