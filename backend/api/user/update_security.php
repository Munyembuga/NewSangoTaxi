<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->user_id)) {
    // Check if security settings exist
    $check_query = "SELECT id FROM user_security_settings WHERE user_id = :user_id";
    $check_stmt = $db->prepare($check_query);
    $check_stmt->bindParam(":user_id", $data->user_id);
    $check_stmt->execute();
    
    if ($check_stmt->rowCount() > 0) {
        // Update existing settings
        $query = "UPDATE user_security_settings SET 
                  enable_driver_calls = :enable_driver_calls,
                  share_live_location = :share_live_location,
                  private_mode = :private_mode,
                  updated_at = CURRENT_TIMESTAMP
                  WHERE user_id = :user_id";
    } else {
        // Insert new settings
        $query = "INSERT INTO user_security_settings (user_id, enable_driver_calls, share_live_location, private_mode) 
                  VALUES (:user_id, :enable_driver_calls, :share_live_location, :private_mode)";
    }
    
    $stmt = $db->prepare($query);
    $stmt->bindParam(":user_id", $data->user_id);
    $stmt->bindParam(":enable_driver_calls", $data->enable_driver_calls, PDO::PARAM_BOOL);
    $stmt->bindParam(":share_live_location", $data->share_live_location, PDO::PARAM_BOOL);
    $stmt->bindParam(":private_mode", $data->private_mode, PDO::PARAM_BOOL);
    
    if ($stmt->execute()) {
        http_response_code(200);
        echo json_encode(array("success" => true, "message" => "Security settings updated"));
    } else {
        http_response_code(500);
        echo json_encode(array("success" => false, "message" => "Failed to update settings"));
    }
} else {
    http_response_code(400);
    echo json_encode(array("success" => false, "message" => "User ID required"));
}
?>
