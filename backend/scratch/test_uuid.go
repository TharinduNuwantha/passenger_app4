package main
import "fmt"
func main() {
    var cost *string
    str := "150.00"
    cost = &str
    var price float64
    fmt.Sscanf(*cost, "%f", &price)
    fmt.Println(price)
}
