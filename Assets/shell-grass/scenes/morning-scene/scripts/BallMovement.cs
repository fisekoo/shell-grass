using UnityEngine;

public class BallMovement : MonoBehaviour
{
    public float moveSpeed = 5f; // Speed of the ball movement
    public float maxDistanceFromCamera = 10f; // Maximum distance from the camera
    public float acceleration = 10f;
    private Rigidbody rb;
    private Camera mainCamera;
    private float horizontalInput, verticalInput;
    void Start()
    {
        rb = GetComponent<Rigidbody>();
        mainCamera = Camera.main;
    }
    private void Update()
    {
        horizontalInput = Input.GetAxisRaw("Horizontal");
        verticalInput = Input.GetAxisRaw("Vertical");

    }
    void FixedUpdate()
    {
        // Calculate the movement direction based on camera's perspective
        Vector3 cameraForward = mainCamera.transform.forward;
        cameraForward.y = 0f; // Ignore the camera's y-axis rotation
        Vector3 cameraRight = mainCamera.transform.right;

        // Calculate movement direction
        Vector3 moveDirection = (cameraRight * horizontalInput + cameraForward * verticalInput).normalized;

        // Apply force to accelerate the ball
        Vector3 accelerationForce = moveDirection * acceleration;
        rb.AddForce(accelerationForce, ForceMode.Acceleration);

        // Limit the maximum velocity
        if (rb.velocity.magnitude > moveSpeed)
        {
            rb.velocity = rb.velocity.normalized * moveSpeed;
        }

    }
}