using HTTP

const localhost = "127.0.0.1"
const port = 8081

function main()
    println("http listen test")
    HTTP.listen(localhost, port) do http
        HTTP.setheader(http, "Content-Type" => "text/html")
        write(http, "target uri: $(http.message.target)<BR>")
        write(http, "request body:<BR><PRE>")
        write(http, read(http))
        write(http, "</PRE>")
    end
end

main()