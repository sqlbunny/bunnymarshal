package bunnymarshal

import "fmt"

// UnknownExpandableError is returned when trying to expand a relationship that doesn't exist.
type UnknownExpandableError struct {
	Model      string
	Expandable string
}

// Error implements the error interface
func (e *UnknownExpandableError) Error() string {
	return fmt.Sprintf("Invalid expand '%s' for object '%s'", e.Expandable, e.Model)
}

// UnknownMarshalerError is returned when trying to marshal a model with a marshaler that doesn't exist
type UnknownMarshalerError struct {
	Model     string
	Marshaler string
}

// Error implements the error interface
func (e *UnknownMarshalerError) Error() string {
	return fmt.Sprintf("Unknown marshaler '%s' for object '%s'", e.Marshaler, e.Model)
}
