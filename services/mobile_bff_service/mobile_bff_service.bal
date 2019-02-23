import ballerina/http;
import ballerina/log;
import ballerinax/docker;
import ballerinax/kubernetes;

// Kubernetes related config. Uncomment for Kubernetes deployment.
// *******************************************************

//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"ballerina-guides-mobile-bff-service",
//    path:"/mobile-bff",
//    targetPath:"/mobile-bff"
//}

//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"ballerina-guides-mobile-bff-service"
//}

//@kubernetes:Deployment {
//    image:"ballerina.guides.io/mobile_bff_service:v1.0",
//    name:"ballerina-guides-mobile-bff-service",
//    dockerCertPath:"/Users/ranga/.minikube/certs",
//    dockerHost:"tcp://192.168.99.100:2376"
//}

// Docker related config. Uncomment for Docker deployment.
// *******************************************************

//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"mobile_bff_service",
//    tag:"v1.0"
//}

//@docker:Expose{}

listener http:Listener mobile_bff_service_client = new(9090);

// Client endpoint to communicate with appointment management service
// URL for Docker deployment : "http://appointment-mgt-container:9092/appointment-mgt"
http:Client appointmentEP = new("http://localhost:9092/appointment-mgt");

// Client endpoint to communicate with medical record service
// URL for Docker deployment : "http://medical-record-mgt-container:9093/medical-records"
http:Client medicalRecordEP = new("http://localhost:9093/medical-records");

// Client endpoint to communicate with message management service
// URL for Docker deployment : "http://message-mgt-container:9095/message-mgt"
http:Client messageEP = new("http://localhost:9095/message-mgt");

// RESTful service.
@http:ServiceConfig { basePath: "/mobile-bff" }
service mobile_bff_service on mobile_bff_service_client {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/profile"
    }
    resource function getUserProfile(http:Caller caller, http:Request req) {

        log:printInfo("getUserProfile...");

        http:Response response = new;

        // Call Appointment API and get appointment list
        json appointmentList = sendGetRequest(appointmentEP, "/appointment/list");

        // Call Medical Record API and get medical record list
        json medicalRecordList = sendGetRequest(medicalRecordEP, "/medical-record/list");

        // Call Message API and get unread message list
        json unreadMessageList = sendGetRequest(messageEP, "/unread-message/list");

        // Aggregate the responses to a JSON
        json profileJson = {};
        profileJson.Appointments = appointmentList.Appointments;
        profileJson.MedicalRecords = medicalRecordList.MedicalRecords;
        profileJson.Messages = unreadMessageList.Messages;

        // Set JSON payload to response
        response.setJsonPayload(untaint profileJson);

        // Send response to the client.
        var result = caller->respond(response); 
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }

    // This API may have more resources for other functionalities
}

// Function which takes http client endpoint and context as a input
// This will call given endpoint and return a json response
function sendGetRequest(http:Client client1, string context) returns (json) {

    var response = client1->get(context);
    if (response is error) {
        log:printError("Error sending response", err = response);
    } else {
        var value = response.getJsonPayload();
        if (value is json) {
            return value;
        } else {
            log:printError("Unable to get json payload from response", err = value);
        }
    }
}