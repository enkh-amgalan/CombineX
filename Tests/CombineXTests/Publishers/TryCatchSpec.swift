import CXShim
import CXTestUtility
import Nimble
import Quick

class TryCatchSpec: QuickSpec {
    
    override func spec() {
        
        afterEach {
            TestResources.release()
        }
        
        // MARK: - Send Values
        describe("Send Values") {
            
            // MARK: 1.1 should use new publisher if upstream ends with error
            it("should use new publisher if upstream ends with error") {
                let p0 = Fail<Int, TestError>(error: .e0)
                let p1 = Publishers.Sequence<[Int], TestError>(sequence: [1, 2, 3]).append(Fail(error: .e0))
                
                let pub = p0.tryCatch { _ in p1 }
                let sub = makeTestSubscriber(Int.self, Error.self, .unlimited)
                
                pub.subscribe(sub)
                
                let got = sub.eventsWithoutSubscription.mapError { $0 as! TestError }
                
                let valueEvents = [1, 2, 3].map { TracingSubscriberEvent<Int, TestError>.value($0) }
                let expected = valueEvents + [.completion(.failure(.e0))]
                
                expect(got) == expected
            }
            
            // MARK: 1.2 should send as many value as demand
            it("should send as many value as demand") {
                let p0 = Publishers.Sequence<[Int], TestError>(sequence: Array(0..<10)).append(Fail<Int, TestError>(error: .e0))
                let p1 = Publishers.Sequence<[Int], TestError>(sequence: Array(10..<20))
                
                let pub = p0.tryCatch { _ in p1 }
                let sub = TracingSubscriber<Int, Error>(receiveSubscription: { s in
                    s.request(.max(10))
                }, receiveValue: { v in
                    [0, 10].contains(v) ? .max(1) : .none
                }, receiveCompletion: { _ in
                })
                
                pub.subscribe(sub)
                
                let got = sub.eventsWithoutSubscription.mapError { $0 as! TestError }
                let events = (0..<12).map { TracingSubscriberEvent<Int, TestError>.value($0) }
                expect(got) == events
            }
            
            // MARK: 1.3 should fail if error handle throws an error
            it("should fail if error handle throws an error") {
                typealias Pub0 = Fail<Int, TestError>
                typealias Pub1 = Publishers.Sequence<[Int], TestError>
                let p0 = Pub0(error: .e0)
                
                let pub: Publishers.TryCatch<Pub0, Pub1> = p0.tryCatch { _ in throw TestError.e2 }
                let sub = makeTestSubscriber(Int.self, Error.self, .unlimited)
                
                pub.subscribe(sub)
                
                let got = sub.eventsWithoutSubscription.mapError { $0 as! TestError }
                expect(got) == [.completion(.failure(.e2))]
            }
        }
    }
}
