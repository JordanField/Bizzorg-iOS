//
//  NetworkingFunctions.swift
//  BizzorgServerTest
//
//  Created by Jordan Field on 15/04/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import Foundation

/**
 This file contains all of the functions and classed that are used by the 
 Bizzorg client to communicate with the Bizzorg server.
 */

/**
 When a response is receieved by a server, it is packaged up into a 
 DataTaskResponse object with the response information.
 
 Properties
 ==========
 `data`: A `Data` object that contains the HTTP body of the server's response.
 
 `response`: The HTTP URL response from the server with the status code
 e.g. 200 or 404.
 
 `error`: If something goes wrong during the request or response, this will
 be populated with the apppropriate error.
 
 `validated`: Boolean value that can be used to check the response has 
 no errors.
 
 `statusCode`: The HTTP Status code of the response (e.g. 200, 404, 500)
 */
class DataTaskResponse {
  var data: Data?
  var response: HTTPURLResponse?
  var error: Error?
  
  var validated: Bool {
    return error == nil
  }
  
  var statusCode: Int? {
    return response?.statusCode
  }
  
  ///initialises a new DataTaskResponse via a 3-value tuple identical to the
  ///one returned by the URLSession.dataTask() function callback.
  init(responsePacket: (data: Data?, response: URLResponse?, error: Error?)) {
    data = responsePacket.data
    //Convert the response from the response packet to a HTTPURLResponse
    //instead of a URLResponse so that the status code can be retrieved.
    response = responsePacket.response as? HTTPURLResponse
    error = responsePacket.error
    
    //If the response object passed to the function is nil, assign the no
    //response from server error to the error property. If no data is supplied
    //assign the no data recieved error instead.
    if response == nil {
      error = NetworkError.noResponseFromServer
    } else if data == nil {
      error = NetworkError.noDataRetrievedFromServer
    }
  }
}

/**
 A wrapper for a text or binary based file to be uploaded to the server.
 
 Properties
 ==========
  `data`: The raw binary/text data for the file.
 
  `name`: The name of the form field, e.g. `profile-picture`.
 
  `contentType`: the file's type, e.g. `image/jpeg`.
 
  `fileName`: The name of the file to be uploaded, e.g. `myImage.jpg`.
 */
class UploadableFile {
 
  var data: Data = Data()
  var name: String = String()
  var contentType: String?
  var fileName: String?
  
  /**
   Converts the file item into a data string for use in the
   `form-data` content disposition with a HTTP server.
   
   In order to upload files to my Django server I have to do it via a form,
   uploading the raw binary data of the file along with the other relevant
   data in the `form-data` content type. A typical form data body looks like
   this:
   
   OST / HTTP/1.1
   Content-Type: multipart/form-data; boundary=--------------7353230313999631669
   Content-Length: 82
   
   --------------7353230313999631669
   Content-Disposition: form-data; name="text1"
   
   text default
   --------------7353230313999631669
   Content-Disposition: form-data; name="file1"; filename="a.txt"
   Content-Type: text/plain
   
   ~Contents of a.txt.~
   --------------7353230313999631669--
   
   You can see the boundary being used here to separate fields in the form, and
   the final boundary beig used to denote the end of the data.
   
   - parameter boundary: The boundary string used to separate form items.
   */
  func generateFieldItem(_ boundary: String) -> Data {
    //Create an empty string
    var itemHeaderString = ""
    
    //append the opening boundary to the string, to denote a new form field.
    itemHeaderString.append("--\(boundary)\r\n")
    
    //append the content disposition to the header string.
    itemHeaderString.append("content-disposition: form-data; ")
    
    //append the field name to the string.
    itemHeaderString.append("name=\"\(name)\"")
    
    //If the uploadable file has a denoted file name:
    if fileName != nil {
      //append it to the header string.
      itemHeaderString.append("; filename=\"\(fileName!)\"")
    }
    //append a line break to separate the filename from the content type.
    itemHeaderString.append("\r\n")
    
    //If the file has a denoted content type:
    if contentType != nil {
      //append it to the header string with a new line to separate it from
      //the raw data.
      itemHeaderString.append("Content-Type: \(contentType!)\r\n\r\n")
    } else {
      //append a newline to separate the header string from the raw data.
      itemHeaderString.append("\r\n")
    }
    
    //encode the header string into binary data.
    let itemHeaderData = itemHeaderString.data(using: .utf8)!
    
    //create a new empty data object to build the field item from
    var itemData = Data()
    //append the newly-created header
    itemData.append(itemHeaderData)
    //append the raw binary data.
    itemData.append(data)
    //append a new line to separate the raw data from the next field item.
    itemData.append("\r\n".data(using: .utf8)!)
    return itemData
  }
  
}

/**
 The `BizzorgCall` object is the backbone of the Bizzorg app; it is the
 object that acts as the mediator between the client and the server. it
 encapsulates the request and response in one object, and uses asynchronous
 functions and callbacks to provide the data as soon as it arrives.
 
 Properties
 ==========
 `call`: The url the request will be made to.
 
 `restMethod`: The REST method used in the request e.g. POST or GET.
 
 `data`: A Data object that encapsulated any data to be sent in the request
  body.
 
 `urlRequest`: A private variable used by a UrlSession object to make the
  request.
 
 `serverResponse`: a DataTaskResponse Object that is initially nil but is
 populated with the details of the server response once it arrives.
 
 `contentType`: A string denoting the HTTP content type of the data being
 sent.
 
 `files`: Computed variable that is used when uploading files e.g. profile
 pictures to the server, code automatically generates the correct multipart
 form for each file.
 
 `responseValidated`: Boolean value that can be used to ensure a response
 has been recieved from the server and that response is valid to use.
 */
class BizzorgCall {
  var call: URL
  var restMethod: RESTMethod
  var data: Data?
  private var urlRequest: URLRequest?
  var serverResponse: DataTaskResponse?
  var contentType: String?
  
  enum RESTMethod: String {
    case GET, POST, PUT, PATCH, DELETE
  }
  
  var files: [UploadableFile] = [] {
    willSet {
      //Check there is a new value that isnt empty.
      guard newValue.count != 0 else {
        //exit if it is.
        return
      }
      
      //Generate a new multipart-form boundary.
      let boundary = generateBoundary()
      
      //Set the content type to a multipart form with the added boundary.
      contentType = "multipart/form-data; boundary=\(boundary)"
      
      //Create a new Data object to populate with the request data.
      var formData = Data()
      
      //For each file in the list
      for file in newValue {
        //add the converted data to the formData object.
        formData.append(file.generateFieldItem(boundary))
      }
      
      //The last boundary in the form data contains two preceding dashes,
      //so create it and append it to the formData object.
      let finalBoundary = "--\(boundary)--".data(using: .utf8)!
      formData.append(finalBoundary)
      
      //Finally, set the object's data property to the generated form data.
      data = formData as Data
    }
  }
  
  var responseValidated: Bool {
    //Check that a response has been recieved from the server and that
    //The response recieved does not contain any errors.
    return serverResponse != nil && serverResponse!.validated
  }
  
  ///Initializes a BizzorgCall with a URL and REST method
  init(_ url: URL, method: RESTMethod) {
    call = url
    restMethod = method
  }
  
  ///Initialises a BizzorgCall with a relative string and REST method.
  convenience init(_ relativeString: String, method: RESTMethod) {
    //Generate a URL object from the relative string using the main Bizzorg
    //Url as the base.
    let generatedUrl = URL(string: relativeString, relativeTo: baseUrl)
    //uses the generated URL in the main init method to generate a BizzorgCall.
    self.init(generatedUrl!, method: method)
  }
  
  ///Create the URLRequest from the data in the BizzorgCall object.
  private func generateRequest() {
    //Create a URLRequest object with the call URL
    var request = URLRequest(url: call)
    //Attach a REST Method to the request object. In URLRequest objects the
    //REST method is stored as a string e.g. 'POST', so the raw value of the
    //enum is used.
    request.httpMethod = restMethod.rawValue
    
    //If a CSRF Cookie has been supplied to the client add the token to the
    //HTTP request header.
    if let csrfCookie = getCsrfTokenCookie() {
      request.addValue(csrfCookie.value, forHTTPHeaderField: "X-CSRFToken")
    }
    
    //If the call has a defined request body content type add it to the
    //HTTP request header.
    if contentType != nil {
      request.addValue(contentType!, forHTTPHeaderField: "Content-Type")
    }
    
    //If some data exists in the data field:
    if data != nil {
      //Check that a content type has been specified.
      guard contentType != nil else {
        //If not, create a Error Response.
        serverResponse =
          DataTaskResponse(responsePacket: (nil, nil, NetworkError.badRequest))
        return
      }
      
      //Now data has been verified, add it to the request body.
      request.httpBody = data!
    }
    
    //The url request has been created, so attach it to the object
    urlRequest = request
  }
  
  internal func getCsrfTokenCookie() -> HTTPCookie? {
    let cookieJar = HTTPCookieStorage.shared
    guard let sessionCookies = cookieJar.cookies(for: baseUrl),
      let csrfCookie = sessionCookies.filter({$0.name == "csrftoken"}).first
    else {
      return nil
    }
    return csrfCookie
  }
  
  func sendToServer(_ urlSession: URLSession, callback: @escaping () -> Void) {
    //Generate the URL request for the URLSession.
    generateRequest()
    
    //If something went wrong in the formation of the request, callback to
    //the completion handler to notify it of an error.
    if serverResponse?.error != nil {
      callback()
      return
    }
    
    /*
     Since URL Requests aren't completed instantaneously, I cannot, for 
     instance, assign the result of a URL request to a variable and then 
     do stuff with that variable, as that is all done on the same line at 
     the same time, which is not possible. Instead, a nifty little feature of 
     Swift is used, in that subroutines can be used as arguments in other 
     subroutines. The native URLSession.dataTask() uses this with the 
     completion handler argument. This asynchronous programming prevents the 
     app hanging, as the response is dealt with as soon as it arrives without
     waiting for it.
     */
    
    //Create the session data task from the url request.
    let dataTask = urlSession.dataTask(with: urlRequest!, completionHandler: {
      //This code will be run once the response has been recieved
      //by the client.
      (data, response, error) in
      //generate a DataTaskResponse object with the recieved data and
      //assign it to the BizzorgCall object.
      self.serverResponse =
        DataTaskResponse(responsePacket: (data, response, error))
      //Callback to the completion handler to denote the response has been
      //received and is ready to be used.
      callback()
    })
    //Start communication with the server.
    dataTask.resume()
  }
  
  ///Creates a new random boundary string for use in sending files to the
  ///server.
  func generateBoundary() -> String {
    //Start with the empty string.
    var boundary = ""
    
    //Append a '-' character to the sting four times.
    //boundary == '----'
    for _ in 1...4 {
      boundary.append("-")
    }
    
    //append a random digit to the string 16 times.
    //(
    for _ in 1...16 {
      let digit = Int(arc4random_uniform(10))
      boundary.append("\(digit)")
    }
    return boundary
  }
}

/**
 An extension of the BizzorgCall class that facilitates communication
 with the API.
 
 Properties
 ==========
 `apiData`: Additional computed property unique to BizzorgApiCall that takes
 in a KeyValuePair dictionary and converts it into JSON data when set, and
 converts JSON data into a KeyValuePair dictionary when got.
*/
class BizzorgApiCall: BizzorgCall {
  var apiData: KeyValuePairs? {
    get {
      //Try to convert the data in the data field into a dictionary. If this
      //fails, return nil.
      guard let object =
        try? JSONSerialization.jsonObject(with: data!, options: [])
          as? KeyValuePairs else {
        return nil
      }
      //return the created dictionary.
      return object
    }
    set(dataAsKvp) {
      guard dataAsKvp != nil else {
        return
      }
      //set the request body content type to JSON
      contentType = "application/json"
      //convert the dictionary to JSON and add it to the object.
      data =
        try? JSONSerialization.data(withJSONObject: dataAsKvp!, options: [])
    }
  }
  
  /**Initialises a BizzorgApiCall with a relative string and REST method.
   
   - parameter relativeString: The tail of the URL, what is being requested
   or changed.
   
   - parameter method: The REST method to be used.
   
   */
  convenience init(_ relativeString: String, method: RESTMethod) {
    //Since this is an API call the URL is created with the API URL as
    //the base.
    let generatedUrl = URL(string: relativeString, relativeTo: apiUrl)
    //generate ApiCall object.
    self.init(generatedUrl!, method: method)
  }
  
  /**
   This polymorphic function acts as the translator for the client for the
   server's responses. It converts JSON response objects into native
   Swift data models. It does this by using initialzer functions defined in
   the data models themselves, which they are required to have in order to
   conform to the ApiDataModel protocol.
   */
  func responseObjectsToDataModels<T: ApiDataModel>() throws -> [T] {
    //Create an empty list of the abstract data model that will be populated
    //with translated models.
    var objects: [T] = []
    
    //Ensure that the response actually exists. If not, throw an error to the
    //code that called this function.
    guard serverResponse!.response != nil else {
      throw NetworkError.noResponseFromServer
    }
    
    //Check that the response actually contains data.
    guard let data = serverResponse!.data else {
      throw NetworkError.noDataRetrievedFromServer
    }
    
    //Now that the response has been certified as safe, try to convert it
    //from JSON to a KVP dictionary. If this fails, throw an error denoting
    //the data is not valid JSON. If the JSON converts successfully, retrieve
    //the list of objects from it.
    guard let dataKvp = try?
      JSONSerialization.jsonObject(with: data, options: []) as? KeyValuePairs,
      let dataObjectArray = dataKvp!["objects"] as? [Any] else {
        throw NetworkError.dataNotValidJSON
    }
    
    
    //For each newly created object, try to cast from Any to KeyValuePairs and
    //use the abstract data model's initialization function with a KVP
    //dictionary to create a native instance of the object. If either of
    //these procedures fail, return an error.
    for dataObject in dataObjectArray {
      guard let objectKvp = dataObject as? KeyValuePairs,
        let object = try? T.init(data: objectKvp) else {
          throw DataError.dataConversionFailed
      }
      //If both procedures execute correctly, append the object to the object
      //list.
      objects.append(object)
    }
    //Once all native objects have been coverted, return the list.
    return objects
  }
}

/**Send a username and password to the server for checking. If the username
 and password match an active user, the server sends a User object to the
 client for the client to save to local storage. A session token and CSRF
 token are also sent to the client for use in place of the username and
 password for any subsequent requests.
 
 
 - parameter credentials: A KVP dictionary containing the username and
 password to be sent to the server.
 - parameter urlSession: The `URLSession` object to be used for client-server
 communication.
 - parameter callback: the function that is called when the retrieval is
 complete. The function should take an `Employee?` and `Error?` parameter and
 return no value.
*/
func verifyUser(_ credentials: KeyValuePairs, urlSession: URLSession,
  callback: @escaping (Employee?, Error?) -> Void) {
  
  //Extract the username and password from the KVP dictionary and assign
  //the POST text data needed to a variable.
  let loginData =
  "username=\(credentials["username"]!)&password=\(credentials["password"]!)"
  
  //Create a BizzorgCall object pointing to the Bizzorg login URL and using
  //the HTTP POST Method. Set the call's content type to be basic URL encoded
  //string and add the login data created above to the request body.
  let call = BizzorgCall("groups/login/", method: .POST)
  call.contentType = "application/x-www-form-urlencoded"
  call.data = loginData.data(using: .utf8)
  
  //Send the request to the server.
  call.sendToServer(urlSession) {
    //Once a response has been recieved, assign the response to a constant
    //for later use.
    let response = call.serverResponse!
    
    //Ensure that the response is validated. If not, callback the error to
    //the completion handler function.
    guard response.validated else {
      callback(nil, response.error!)
      return
    }
    
    //Ensure that the HTTP status code is 200 OK, if not, callback an error
    //with the actual status code.
    guard response.statusCode == 200 else {
      callback(nil, NetworkError.serverError(statusCode: response.statusCode!))
      return
    }
    
    //Ensure that the Employee object can actually be created from the data
    //Supplied. If not, callback an error denoting that conversion failed.
    guard let employee =  Employee(data: call.serverResponse!.data!) else {
      callback(nil, DataError.dataConversionFailed)
      return
    }
    
    //All tests on the receieved data have now passed and the employee object
    //has been created and assigned to the variable `employee`, so invoke
    //the callback function with the employee object so more processing can
    //be done.
    callback(employee, nil)
  }
}

/**
 This polymorphic function allows an object to be retrieved from the server and
 converted into a native Swift object for use in the app. This function is used
 to retrieve objects that are denoted by URIs in other objects as well as
 retrieving profile pictures.
 
 In order for this function to work the type that the data is going to be
 converted to must conform to the protocol `initializableFromData`, meaning it
 must have an initializer that takes a Data parameter and nothing else. This
 ensures that the object can be initialised in this function without unexpected
 errors.
 
 - parameter uri: The URL for the object to be recieved.
 - parameter urlSession: The URLSession object to be used for client-server
 communication
 - parameter callback: Function that is called once the object has been
 retrieved, can either contain the converted object or an error denoting what
 failed.
 */
func getObjectFromUri<T: InitializableFromData>(_ uri: URL,
                      urlSession: URLSession,
                      callback: @escaping (T?, Error?) -> Void) {
  //create a bizzorgCall object pointing at the uri parameter with the GET
  //HTTP method.
  let call = BizzorgCall(uri, method: .GET)
  
  //Send the request to the server.
  call.sendToServer(urlSession) {
    //Assign the response once it has been recieved to a constant.
    let response = call.serverResponse!
    
    //Ensure that the response is validate and that the response data is not
    //empty. If not, callback the relevant error.
    guard response.validated && response.data != nil else {
      callback(nil, response.error!)
      return
    }
    
    //Attempt to generate the object from the server data using the abstract
    //type initialiser and assign it to the constant object. if this fails, 
    //callback an error to denote that data conversion failed.
    guard let object = T(data: response.data!) else {
      callback(nil, DataError.dataConversionFailed)
      return
    }
    
    //Now that all procedures have passed successfully, callback the converted
    //object to whatever called this function.
    callback(object, nil)
  }
}

/**
 Attempts to log the user out of the current session.
 
 - parameter urlSession: The URLSession object to use for client-server
 communication.
 
 - parameter callback: The callback function to be used when the log-out
 process completes. the function passed should have one `Error?` parameter and
 return no value.
 */
func attemptLogOut(_ urlSession: URLSession,
                   callback: @escaping (Error?) -> Void) {
  
  //Create a BizzorgCall object pointing to the log-out URL with the POST
  //HTTP method.
  let call = BizzorgCall("groups/logout/", method: .POST)
  
  //Send the call to the server.
  call.sendToServer(urlSession) {
    //Once the response has been recieved, assign it to the constant 'response'.
    let response = call.serverResponse!
    
    //Ensure that the response has been validated with no errors. If not,
    //callback with the appropriate error.
    guard response.validated else {
      callback(response.error!)
      return
    }
    
    //Ensure that the server response status code is 200 OK. If not, callback
    //an error with the status code.
    guard response.statusCode == 200 else {
      callback(NetworkError.serverError(statusCode: response.statusCode!))
      return
    }
    
    //Once all the guard statements have passed I can be sure that log-out
    //has been successful, so remove the logged in user from the cache.
    globalUserDefaults.removeObject(forKey: "logged-in-user")
    
    //Callback to the caller to denote logout has completed.
    callback(nil)
  }
}


