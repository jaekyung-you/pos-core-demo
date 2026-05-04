// Package pos is the POS business logic SDK.
// Exported via gomobile bind as POSCore.xcframework.
package pos

import (
	"encoding/json"
	"time"
)

// Add is the spike validation function.
// If Swift can call this and get the right answer, the bridge works.
func Add(a, b int64) int64 {
	return a + b
}

// --- POS Session State ---

var session posSession

type posSession struct {
	initialized  bool
	runningTotal int64
	lastReceipt  *receiptData
	pendingTx    bool
}

type receiptData struct {
	Items     []itemData `json:"items"`
	Total     int64      `json:"total"`
	Discount  int64      `json:"discount"`
	VAT       int64      `json:"vat"`
	Method    string     `json:"method"`
	Timestamp string     `json:"timestamp"`
}

type itemData struct {
	Name  string `json:"name"`
	Qty   int64  `json:"qty"`
	Price int64  `json:"price"`
}

// Init resets the POS session. Call once at app launch.
func Init() {
	session = posSession{initialized: true}
}

// Charge processes a payment synchronously.
// itemsJSON is a JSON array of {"name", "qty", "price"} objects.
func Charge(amount int64, method string, itemsJSON string) (bool, error) {
	session.pendingTx = true
	defer func() { session.pendingTx = false }()

	var items []itemData
	_ = json.Unmarshal([]byte(itemsJSON), &items)
	if items == nil {
		items = []itemData{}
	}

	vat := int64(float64(amount) * 0.1 / 1.1)
	session.runningTotal += amount
	session.lastReceipt = &receiptData{
		Items:     items,
		Total:     amount,
		Discount:  0,
		VAT:       vat,
		Method:    method,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}
	return true, nil
}

// GetReceipt returns the last receipt as a JSON string, or "" if none.
func GetReceipt() (string, error) {
	if session.lastReceipt == nil {
		return "", nil
	}
	b, err := json.Marshal(session.lastReceipt)
	if err != nil {
		return "", err
	}
	return string(b), nil
}

// GetTodayTotal returns cumulative revenue for the current session.
func GetTodayTotal() int64 {
	return session.runningTotal
}

// CheckPendingTransaction returns true while a Charge call is in progress.
func CheckPendingTransaction() bool {
	return session.pendingTx
}
