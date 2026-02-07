<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->user_id) && !empty($data->pickup_address) && !empty($data->destination_address)) {
    
    // Calculate fare based on distance (simplified)
    $base_fare = 2500; // Standard fare
    if ($data->vehicle_type == 'premium') $base_fare = 4000;
    if ($data->vehicle_type == 'suv') $base_fare = 6000;
    
    $query = "INSERT INTO rides (user_id, pickup_address, pickup_lat, pickup_lng, destination_address, destination_lat, destination_lng, ride_type, fare, scheduled_time) 
              VALUES (:user_id, :pickup_address, :pickup_lat, :pickup_lng, :destination_address, :destination_lat, :destination_lng, :ride_type, :fare, :scheduled_time)";
    
    $stmt = $db->prepare($query);
    $stmt->bindParam(":user_id", $data->user_id);
    $stmt->bindParam(":pickup_address", $data->pickup_address);
    $stmt->bindParam(":pickup_lat", $data->pickup_lat);
    $stmt->bindParam(":pickup_lng", $data->pickup_lng);
    $stmt->bindParam(":destination_address", $data->destination_address);
    $stmt->bindParam(":destination_lat", $data->destination_lat);
    $stmt->bindParam(":destination_lng", $data->destination_lng);
    $stmt->bindParam(":ride_type", $data->vehicle_type);
    $stmt->bindParam(":fare", $base_fare);
    
    $scheduled_time = isset($data->scheduled_time) ? $data->scheduled_time : null;
    $stmt->bindParam(":scheduled_time", $scheduled_time);
    
    if ($stmt->execute()) {
        $ride_id = $db->lastInsertId();
        
        // Find available driver (simplified logic)
        $driver_query = "SELECT d.id, d.full_name, d.phone, v.id as vehicle_id, v.make, v.model, v.plate_number 
                        FROM drivers d 
                        JOIN vehicles v ON d.id = v.driver_id 
                        WHERE d.is_available = 1 AND v.vehicle_type = :vehicle_type 
                        LIMIT 1";
        
        $driver_stmt = $db->prepare($driver_query);
        $driver_stmt->bindParam(":vehicle_type", $data->vehicle_type);
        $driver_stmt->execute();
        
        if ($driver_stmt->rowCount() > 0) {
            $driver = $driver_stmt->fetch(PDO::FETCH_ASSOC);
            
            // Assign driver to ride
            $update_query = "UPDATE rides SET driver_id = :driver_id, vehicle_id = :vehicle_id, status = 'accepted' WHERE id = :ride_id";
            $update_stmt = $db->prepare($update_query);
            $update_stmt->bindParam(":driver_id", $driver['id']);
            $update_stmt->bindParam(":vehicle_id", $driver['vehicle_id']);
            $update_stmt->bindParam(":ride_id", $ride_id);
            $update_stmt->execute();
            
            // Mark driver as unavailable
            $driver_update = "UPDATE drivers SET is_available = 0 WHERE id = :driver_id";
            $driver_update_stmt = $db->prepare($driver_update);
            $driver_update_stmt->bindParam(":driver_id", $driver['id']);
            $driver_update_stmt->execute();
        }
        
        http_response_code(201);
        echo json_encode(array(
            "success" => true,
            "message" => "Ride booked successfully",
            "ride_id" => $ride_id,
            "fare" => $base_fare,
            "driver" => isset($driver) ? $driver : null
        ));
    } else {
        http_response_code(500);
        echo json_encode(array("success" => false, "message" => "Failed to book ride"));
    }
} else {
    http_response_code(400);
    echo json_encode(array("success" => false, "message" => "Required fields missing"));
}
?>
