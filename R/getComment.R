#' Get Comment
#'
#' Get naver news comments
#' if you want to get data only comment, enter command like below.
#' getComment(url)$result$commentList[[1]]
#'
#' @param turl like 'http://news.naver.com/main/read.nhn?mode=LSD&mid=shm&sid1=100&oid=056&aid=0010335895'.
#' @param pageSize is a number of comments per page. defult is 10.
#' @param page is defult is 1.
#' @param sort you can select favorite, reply, old, new. favorite is defult.
#' @return Get data.frame.
#' @export
#' @import httr
#' @import jsonlite
#' @import stringr

getComment <- function(turl = url, pageSize = 10, page = 1,
                       sort = c("favorite", "reply", "old", "new")) {

    sort <- sort[1]
    tem <- stringr::str_split(turl, "[=&]")[[1]]
    ticket <- "news"
    pool <- "cbox5"
    oid <- tem[grep("oid", tem) + 1]
    aid <- tem[grep("aid", tem) + 1]
    templateId <- "view_politics"
    useAltSort <- "&useAltSort=true"

    if(grepl("http://sports.", turl)){
      ticket <- "sports"
      pool <- "cbox2"
      templateId <- "view"
      useAltSort <- ""
    }

    url <- paste0("https://apis.naver.com/commentBox/cbox/web_naver_list_jsonp.json?",
                  "ticket=", ticket,
                  "&templateId=",templateId,
                  "&pool=",pool,
                  "&lang=ko&country=KR&objectId=news",oid, "%2C", aid,
                  "&categoryId=&pageSize=", pageSize,
                  "&indexSize=10&groupId=&page=", page,
                  "&initialize=true", useAltSort,
                  "&replyPageSize=30&moveTo=&sort=",sort)

    con <- httr::GET(url,
                     httr::user_agent("N2H4 using r by chanyub.park mrchypark@gmail.com"),
                     httr::add_headers(Referer = turl))
    tt <- httr::content(con, "text")

    tt <- gsub("_callback", "", tt)
    tt <- gsub("\\(", "[", tt)
    tt <- gsub("\\)", "]", tt)
    tt <- gsub(";", "", tt)
    tt <- gsub("\n", "", tt)

    data <- jsonlite::fromJSON(tt)
    print(paste0("success : ", data$success))
    return(data)

}



#' Get All Comment
#'
#' Get all comments from the provided news article url on naver
#'
#' Works just like getComment, but this function executed in a fashion where it finds and extracts all comments from the given url.
#'
#' @param turl character. News article on 'Naver' such as 'http://news.naver.com/main/read.nhn?mode=LSD&mid=shm&sid1=100&oid=056&aid=0010335895'. News articl url that is not on Naver.com domain will generate an error.
#' @return Get data.frame.
#' @export


getAllComment <- function(turl = url){

    temp        <- getComment(turl,pageSize=1,page=1,sort="favorite")
    numPage     <- ceiling(temp$result$pageModel$totalRows/100)
    comments    <- lapply(1:numPage, function(x) getComment(turl=turl
                                                            , pageSize=100
                                                            , page=x
                                                            , sort="favorite"
                                                            )
                          )
    comments    <- lapply(comments, function(x) x$result$commentList[[1]])
    commentList <- do.call(rbind, lapply(comments, data.frame, stringsAsFactors=FALSE))

    return(commentList)
  }
