<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->username) && !empty($data->password)) {
    $query = "SELECT id, full_name, email, phone, password_hash, job_title, member_type FROM users WHERE email = :username OR phone = :username";
    
    $stmt = $db->prepare($query);
    $stmt->bindParam(":username", $data->username);
    $stmt->execute();
    
    if ($stmt->rowCount() > 0) {
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (password_verify($data->password, $row['password_hash'])) {
            // Get security settings
            $security_query = "SELECT * FROM user_security_settings WHERE user_id = :user_id";
            $security_stmt = $db->prepare($security_query);
            $security_stmt->bindParam(":user_id", $row['id']);
            $security_stmt->execute();
            $security_settings = $security_stmt->fetch(PDO::FETCH_ASSOC);
            
            $response = array(
                "success" => true,
                "message" => "Login successful",
                "user" => array(
                    "id" => $row['id'],
                    "full_name" => $row['full_name'],
                    "email" => $row['email'],
                    "phone" => $row['phone'],
                    "job_title" => $row['job_title'],
                    "member_type" => $row['member_type']
                ),
                "security_settings" => $security_settings ?: array(
                    "enable_driver_calls" => false,
                    "share_live_location" => false,
                    "private_mode" => false
                )
            );
            
            http_response_code(200);
            echo json_encode($response);
        } else {
            http_response_code(401);
            echo json_encode(array("success" => false, "message" => "Invalid credentials"));
        }
    } else {
        http_response_code(401);
        echo json_encode(array("success" => false, "message" => "User not found"));
    }
} else {
    http_response_code(400);
    echo json_encode(array("success" => false, "message" => "Username and password required"));
}
?>
