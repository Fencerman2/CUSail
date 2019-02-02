/*-----------------------------------------------------------------
 CU Sail
 Cornell University Autonomous Sailboat Team

 Navigation
 Allows determination of the appropriate Sail and Tail angle and setting of the Servos

 Code has been tested and run on an Arduino Due

 Sail Servo: HS-785HB by Hitec
 Tail Servo: HS-5646WP by Hitec
--------------------------------------------------------------------*/
<<<<<<< HEAD
#include "Servo.h"
#include <String.h>
#include <WString.h>

/*----------Type Definitions----------*/
#ifndef coordinate
#define coordinate
typedef struct coordinate{
  double latitude; // float latitude
  double longitude; // float longitudes
} coord_t;
=======
#include <Servo.h>
#include <Arduino.h>
#include "coordinates.cpp"
/*----------Type Definitions----------*/
coord_t;
>>>>>>> 4eddd31f83ac56c1dd78147404c938d406d24046

typedef struct coord_xy {
  double x; // float x coord
  double y; // float y coord
} coord_xy;
class Boat_Controller{
public:
  float sail_angle;
  float tail_angle;
  float boat_direction;
  coord_xy location;
  Servo tailServo;
  Servo sailServo;
  float detection_radius;
  float port_boundary;
  float starboard_boundary;
  bool isTacking;
  String PointofSail;
  float angle_of_attack = 10;
  float static optimal_angle = 60;

  //Sets the angle of the main sail
  void set_sail_angle (float angle);

  //Sets the angle of the tail sail
  void set_tail_angle (float angle);

};
/*
An object of class Navigation_Controller represents the abstract
(not directly related to the boat) variables and operations performed on them to
navigate a body of water.
*/
class Navigation_Controller {
public:
  coord_xy waypoint_array[];
  float angleToWaypoint;
  float normalDistance;
  bool isTacking;
  float intendedAngle;
  String portOrStarboard;
  float maxDistance;
  int numWP;
  int currentWP;
  float dirAngle;
  float offset;
  float wind_direction;
  float port_boundary;
  float starboard_boundary;
  float upperWidth;
  float lowerWidth;
  float r[2];
  float w[2];

<<<<<<< HEAD
class Boat_Controller {
 public:
  float sail_angle;
  float tail_angle;
  float boat_direction;
  coord_xy location;
  Servo tailServo;
  Servo sailServo;
  float detection_radius;
  float port_boundary;
  float starboard_boundary;
  bool isTacking;
  String PointofSail;
  float angle_of_attack = 10;
  constexpr float static optimal_angle = 60;

  //Sets the angle of the main sail
  void set_sail_angle(float angle);

  //Sets the angle of the tail sail
  void set_tail_angle(float angle);

};

class Navigation_Controller{
  coord_xy waypoint_array[];
  float angleToWaypoint;
  float normalDistance;
  bool isTacking;
  float intendedAngle;
  String portOrStarboard;
  float maxDistance;
  int numWP;
  int currentWP;
  float dirAngle;
  float offset;
  float wind_direction;
  float port_boundary;
  float starboard_boundary;
  float upperWidth;
  float lowerWidth;
  float r[2];
  float w[2];
};
#endif

=======
};
>>>>>>> 4eddd31f83ac56c1dd78147404c938d406d24046
/*----------Predefined Variables----------*/
#define maxPossibleWaypoints 100
#define tailServoPin 8
#define sailServoPin 9
//Optimal angle to go at if we cannot go directly to the waypoint
//Puts us on a tack or jibe
//Different values for top and bottom of polar plot
// #define optPolarTop 60//20
// #define optPolarBot 60//40
// #define angleOfAttack 10
// #define detectionRadius 15

/*----------Global Variables-----------*/
extern coord_xy wayPoints[maxPossibleWaypoints]; //the array containing the waypoints with type coord_t


/*----------Functions----------*/
void initializer(void);

void calcIntendedAngle(Boat_Controller bc, Navigation_Controller nc);
/*Determines whether boat is above upper boundary
*/
bool aboveBounds(float upperWidth, coord_xy location, coord_xy nextwp, String pointOfSail);
/*Determines whether boat is below lower boundaryd
*/
bool belowBounds(float lowerWidth, coord_xy location, coord_xy nextwp, String pointOfSail);

/*Sets sail and tail angle given information from nShort */
void nav();