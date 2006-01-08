;;  utilities.lisp - Various utilities.
;;  Copyright (C) 2004  Rob Myers rob@robmyers.org
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

(defmethod debug-message (msg)
  "Write the message to the error stream, not to standard output."
  (format *debug-io* 
	  "~A~%" 
	  msg)
  (finish-output *debug-io*))

(defmethod advisory-message (msg)
  "Write the message to the error stream, not to standard output. No newline."
  (format *debug-io* 
	  msg)
  (finish-output *debug-io*))

(defmethod random-range (a b)
  "Make a random number from a to one below b."
  (let ((range (- b a)))
    (if (= range 0) ;; OpenMCL's random doesn't like 0
	a
	(+ (random range) a))))