//
//  HttpClient.swift
//  
//
//  Created by Yehor Popovych on 10/28/20.
//

import Foundation
#if os(Linux)
import FoundationNetworking
#endif

public class HttpRpcClient: RpcClient {
    public let url: URL
    public var responseQueue: DispatchQueue
    public var headers: Dictionary<String, String>
    public var encoder: JSONEncoder
    public var decoder: JSONDecoder
    public var session: URLSession
    
    public init(
        url: URL, responseQueue: DispatchQueue = .main,
        headers: [String: String] = [:], session: URLSession = .shared,
        encoder: JSONEncoder = .substrate, decoder: JSONDecoder = .substrate
    ) {
        self.url = url; self.responseQueue = responseQueue
        self.encoder = encoder; self.decoder = decoder
        self.session = session
        self.headers = ["Content-Type": "application/json"]
        self.headers.merge(headers) { (_, new) in new }
    }
    
    public func call<P, R>(method: Method, params: P, timeout: TimeInterval = 60, response: @escaping RpcClientCallback<R>)
        where P: Encodable & Sequence, R: Decodable
    {
        let request = JsonRpcRequest(id: 1, method: method.substrateMethod, params: params)
        guard let body = _encode(value: request, response: response) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = body
        req.timeoutInterval = timeout
        for (k, v) in headers {
            req.addValue(v, forHTTPHeaderField: k)
        }
        session.dataTask(with: req) { data, urlResponse, error in
            guard let urlResponse = urlResponse as? HTTPURLResponse, let data = data, error == nil else {
                let err: RpcClientError = error != nil
                    ? .transport(error: error!)
                    : .unknown(error: nil)
                self.responseQueue.async { response(.failure(err)) }
                return
            }
            
            let status = urlResponse.statusCode
            guard status >= 200 && status < 300 else {
                self.responseQueue.async {
                    response(.failure(.http(code: status, body: data)))
                }
                return
            }
            let result = self._decode(data: data, JsonRpcResponse<R>.self)
                .flatMap {
                    $0.isError
                        ? .failure(.rpc(error: $0.error!))
                        : .success($0.result!)
                }
            self.responseQueue.async { response(result) }
        }.resume()
    }
    
    private func _encode<Req: Encodable, Res: Decodable>(
        value: Req, response: @escaping RpcClientCallback<Res>
    ) -> Data? {
        do {
            return try encoder.encode(value)
        } catch let error as EncodingError {
            responseQueue.async { response(.failure(.encoding(error: error))) }
            return nil
        } catch {
            responseQueue.async { response(.failure(.unknown(error: error))) }
            return nil
        }
    }
    
    private func _decode<Res: Decodable>(data: Data, _ type: Res.Type) -> Result<Res, RpcClientError> {
        do {
            return try .success(decoder.decode(Res.self, from: data))
        } catch let error as DecodingError {
            return .failure(.decoding(error: error))
        } catch {
            return .failure(.unknown(error: error))
        }
    }
}
