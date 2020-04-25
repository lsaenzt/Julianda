# ------------------------------------------------------------------------------------
# OrderBook Structs and JSON3 types
# ------------------------------------------------------------------------------------
mutable struct orderBookBucket
    price
    longCountPercent
    shortCountPercent

    orderBookBucket() = new()
end

mutable struct orderBook
    instrument
    time
    price
    bucketWidth
    buckets::Vector{orderBookBucket}

    orderBook() = new()
end

mutable struct orderBookTopLayer
    orderBook::orderBook

    orderBookTopLayer() = new()
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{orderBookTopLayer}) = JSON3.Mutable()
JSON3.StructType(::Type{orderBook}) = JSON3.Mutable()
JSON3.StructType(::Type{orderBookBucket}) = JSON3.Mutable()

# ------------------------------------------------------------------------------------
# PositionBook Structs and JSON3 types
# ------------------------------------------------------------------------------------

mutable struct positionBookBucket
    price
    longCountPercent
    shortCountPercent

    positionBookBucket() = new()
end

mutable struct positionBook
    instrument
    time
    price
    bucketWidth
    buckets::Vector{positionBookBucket}

    positionBook() = new()
end

mutable struct positionBookTopLayer
    positionBook::positionBook

    positionBookTopLayer() = new()
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{positionBookTopLayer}) = JSON3.Mutable()
JSON3.StructType(::Type{positionBook}) = JSON3.Mutable()
JSON3.StructType(::Type{positionBookBucket}) = JSON3.Mutable()

#------------------------------------------------------------------------------------
# Coercion 
#------------------------------------------------------------------------------------

# Conversions to proper Julia types
function coerceOrderBook(ob::orderBook)
    RFC = Dates.DateFormat("yyyy-mm-ddTHH:MM:SSZ")

    ob.time = DateTime(ob.time, RFC)
    ob.price = parse(Float32, ob.price)
    ob.bucketWidth = parse(Float32, ob.bucketWidth)
    for bucket in ob.buckets
        bucket = coerceOrderBookBucket(bucket)
    end

    return ob
end

function coerceOrderBookBucket(bucket::orderBookBucket)
    bucket.price = parse(Float32, bucket.price)
    bucket.longCountPercent = parse(Float32, bucket.longCountPercent)
    bucket.shortCountPercent = parse(Float32, bucket.shortCountPercent)

    return bucket
end


# Conversions to proper Julia types
function coercePositionBook(ob::positionBook)
    RFC = Dates.DateFormat("yyyy-mm-ddTHH:MM:SSZ")

    ob.time = DateTime(ob.time, RFC)
    ob.price = parse(Float32, ob.price)
    ob.bucketWidth = parse(Float32, ob.bucketWidth)
    for bucket in ob.buckets
        bucket = coercePositionBookBucket(bucket)
    end

    return ob
end

function coercePositionBookBucket(bucket::positionBookBucket)
    bucket.price = parse(Float32, bucket.price)
    bucket.longCountPercent = parse(Float32, bucket.longCountPercent)
    bucket.shortCountPercent = parse(Float32, bucket.shortCountPercent)

    return bucket
end