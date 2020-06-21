using HTTP
import HTTP:bytes
using JSON
using JSON2
"""
Routingを行う場合
"""
const localhost = "127.0.0.1"
const port = 8081
const headers = ["Content-Type" => "application/json"]

struct TestStruct
    name::String
    number::Int
end

# apitest/nameのname部分とTestStructを紐づけ，uniqueなnameを持つ
test_structs = Dict{String, TestStruct}()

"""
辞書型をJSON文字列に変換する
"""
function dict2json_str(json_dict::AbstractDict)
    buf = IOBuffer()
    JSON.print(buf, json_dict, 4)
    return json_str = String(take!(buf))
end

"""
POSTされたJSONを保存する
"""
function postTest(req::HTTP.Request)::HTTP.Response
    println("createTest")
    request_body = String(HTTP.payload(req))
    try
        # String を parseして　TestStruct型変数作成
        test_struct = JSON2.read(request_body, TestStruct)
        # デフォルトはtest_structのnameをkeyとする
        push!(test_structs, test_struct.name=>test_struct)
        return HTTP.Response(200)
    catch
        return HTTP.Response(500)
    end
end

"""
GET，nameをpathから取得して，そのnameを持つデータをJSONで返す
"""
function getTest(req::HTTP.Request)::HTTP.Response
    println("getTest")
    try
        uri = HTTP.URI(req.target)
        params = HTTP.queryparams(uri)
        # testapi/name, get name
        name = HTTP.URIs.splitpath(uri.path)[2]
        test_struct::TestStruct = test_structs[name]
        json_str = JSON2.write(test_struct)
        json_dict = JSON2.read(json_str, Dict)
        json_str = dict2json_str(json_dict)
        return HTTP.Response(200, headers, body = bytes(json_str))
    catch
        body = """
        {
            "message": "No data"
        }
        """
        return HTTP.Response(404, headers, body = bytes(body))
    end
end

"""
PUT データを作成 or 更新する
nameを取得して，その他の値はbodyから取得する
あとはpostと同じ，request.bodyに"name":nameを追加してpostTestに投げる
"""
function putTest(req::HTTP.Request)::HTTP.Response
    println("putTest")
    try
        uri = HTTP.URI(req.target)
        params = HTTP.queryparams(uri)
        # testapi/name, get name
        name = HTTP.URIs.splitpath(uri.path)[2]
        json_dict = JSON2.read(String(req.body), Dict)
        # すでに"name"が存在する場合は，更新される
        push!(json_dict, "name"=>name)
        json_str = JSON2.write(json_dict)
        test_struct = JSON2.read(json_str, TestStruct)
        push!(test_structs, name=>test_struct)
        return HTTP.Response(200)
    catch
        body = """
        {
            "message": "No data"
        }
        """
        return HTTP.Response(404, headers, body = bytes(body))
    end
end

"""
DELETE データを削除する
pathからnameを取得して，そのnameを持つstructを削除する
"""
function deleteTest(req::HTTP.Request)::HTTP.Response
    println("deleteTest")
    try
        uri = HTTP.URI(req.target)
        params = HTTP.queryparams(uri)
        # testapi/name, get name
        name = HTTP.URIs.splitpath(uri.path)[2]
        # delete
        filter!(x->x.first != name, test_structs)
        println("deleted")
        return HTTP.Response(200)
    catch
        body = """
        {
            "message": "No data"
        }
        """
        return HTTP.Response(404, headers, body = bytes(body))
    end
end

const TEST_ROUTER = HTTP.Router()
HTTP.@register(TEST_ROUTER, "POST", "/testapi", postTest)
HTTP.@register(TEST_ROUTER, "GET", "/testapi/*", getTest)
HTTP.@register(TEST_ROUTER, "PUT", "/testapi/*", putTest)
HTTP.@register(TEST_ROUTER, "DELETE", "/testapi/*", deleteTest)
println("listen...")
HTTP.serve(TEST_ROUTER, localhost, port)