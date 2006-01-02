;;  drawing.lisp - Drawing around shapes.
;;  Copyright (C) 2004-5  Rob Myers rob@robmyers.org
;;
;;  This program is free software; you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation; either version 2 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.
;;
;;  You should have received a copy of the GNU General Public License
;;  along with this program; if not, write to the Free Software
;;  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

(in-package "DRAW-SOMETHING")

(defclass pen-state ()
  ((location :accessor location 
	     :initform (make-instance 'point) 
	     :initarg :location
	     :documentation "The current location of the pen.")
  (direction :accessor direction
	     :initform 0.0 
	     :initarg :direction
	     :documentation "The current heading of the pen, in radians anticlockwise.")
  (pen-down :accessor pen-down 
	    :initform t
	    :initarg :pen-down
	    :documentation "Whether the pen is in contact with the paper."))
  (:documentation "The pen's current state."))

(defclass pen-configuration ()
  ((speed :accessor speed
	 :initform 1.0
	 :initarg :speed
	 :documentation "How far the pen moves each step.")
  (pen-distance :accessor pen-distance
		 :initform 2.0
		 :initarg :distance
		 :documentation "The distance the pen should be from the skeletal (quide) shape it is drawing around.")
  (distance-fuzz :accessor distance-fuzz
		 :initform 1.4
		 :initarg :distance-fuzz
		 :documentation "How far the pen can drift from the distance it should be from the skeletal (guide) shape.")
  (turn-step :accessor turn-step 
	     :initform 0.01
	     :initarg :turn-step
	     :documentation "How far the pen turns at a time."))
  (:documentation "Constraints for a pen."))

(defclass pen (pen-state
	       pen-configuration)
  ()
  (:documentation "A pen with state and configuration."))

(defmethod turn ((p pen) delta)
  "Turn the pen anticlockwise the given amount in radians."
  (setf (direction p) 
	(+ (direction p) 
	   delta)))

(defmethod turn-left ((p pen) delta)
  "Turn the pen left by the given amount in degrees,"
  (turn p (- delta)))

(defmethod turn-right ((p pen) delta)
  "Turn the pen right by the given amount in degrees,"
  (turn p delta))

(defmethod move-forward ((p pen) distance)
  "Move the pen forward the given distance at the pen's current angle."
  (setf (location p) 
	(next-point p distance)))

(defmethod move-backward ((p pen) distance)
  "Move the pen backward the given distance at the pen's current angle."
  (move-forward p (- distance)))

(defmethod next-point-x ((p pen) distance)
  "The x co-ordinate of the next point the pen would move forward to."
  (+ (x (location p)) 
     (* distance 
	(sin (direction p)))))

(defmethod next-point-y ((p pen) distance)
  "The y co-ordinate of the next point the pen would move forward to."
  (+ (y (location p)) 
     (* distance 
	(cos (direction p)))))

(defmethod next-point ((p pen) distance)
  "Calculate the next point the pen would move forward to, but don't move the pen to it."
    (make-instance 'point 
		   :x (next-point-x p distance)
		   :y (next-point-y p distance)))

(defmethod path-ready-to-close (sketch (p pen) (first-point point))
  "Would drawing the next section bring us close enough to the start of the path that we should close the path?"
  (and (> (length sketch) 2)
       (< (distance (aref sketch (- (length sketch) 
				    1)) 
		    first-point)
	  (speed p))))

(defmethod draw-around ((poly polyline) (p pen))
  "Draw around a polygon using a pen."
  (start-drawing poly p)
  (let* ((first-point (location p))
	 (sketch (make-array 1 
			     :adjustable t
			     :fill-pointer 1
			     :initial-element first-point))
	(guard-count 10000))
    ;;Make the rest, finishing when < step from the original point
    (loop until (or (path-ready-to-close sketch p first-point)
    				(= guard-count
    				    0))
	  do (vector-push-extend (draw-step poly p) 
				 sketch)
	;; hack to protect against endless loop, remove when fixed
	(setf guard-count
	      (- guard-count
	         1)))
    (vector-push-extend first-point
			sketch)
    sketch))

(defmethod start-drawing ((poly polyline) (p pen))
  "Start the drawing turtle just above the top left point of the polygon."
  (let ((top-left (highest-leftmost-point (points poly))))
    (setf (location p)
	  (make-instance 'point 
			 :x (x top-left) 
			 :y (+ (y top-left)  
			       (pen-distance p))))))

(defmethod next-pen-distance ((poly polyline) (p pen))
  "How far the pen will be from the guide shape when it next moves forwards."
  (distance (next-point p (speed p)) 
	    poly))

(defmethod next-pen-too-close ((poly polyline) (p pen))
  "Will the pen move to be too close from the guide shape next time?"
;;  (< (next-pen-distance poly p) 
;;     (pen-distance p)))
  (< (random (distance-fuzz p))
     (- (next-pen-distance poly p)
	(pen-distance p))))

(defmethod next-pen-too-far ((poly polyline) (p pen))
  "Will the pen move to be too far from the guide shape next time?"
;  (> (next-pen-distance poly p) 
;     (pen-distance p)))
  (< (random (distance-fuzz p))
     (- (pen-distance p)
	(next-pen-distance poly p))))
     
(defmethod ensure-next-pen-far-enough ((poly polyline) (p pen))
  "If the pen would move too close next time, turn it left until it wouldn't."
  (loop while (next-pen-too-close poly p)
     do (turn-left p (turn-step p))))
     
(defmethod ensure-next-pen-close-enough ((poly polyline) (p pen))
  "If the pen would move too far next time, turn it right until it wouldn't."
  (loop while (next-pen-too-far poly p)
     do (turn-right p (turn-step p))))
    
(defmethod adjust-next-pen ((poly polyline) (p pen))
  "Set the pen back on the correct path around the shape."
    (ensure-next-pen-far-enough poly p)
    (ensure-next-pen-close-enough poly p))

(defmethod draw-step ((poly polyline) (p pen))
  "Find the next point forward along the drawn outline of the shape."
  (adjust-next-pen poly p)
  (move-forward p (speed p))
  (location p))


;(test
; (let* ((a (make-instance 'point :x 0 :y 0))
;	(b (make-instance 'point :x 0 :y 10))
;	(c (make-instance 'point :x 10 :y 10))
;	(d (make-instance 'point :x 10 :y 0))
;	(hull (make-instance 'polyline :points (list d c b a)))
;	(p (start-drawing hull (make-instance 'pen))))
;   (draw-step hull p)))