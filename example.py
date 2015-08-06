from mal import MyAnimeList

#Example 1
data = MyAnimeList('naruto', ('user','password')).anime
for anime in data:
  print(anime.title + "\n")

#Example 2
data = MyAnimeList('one piece', ('user','password')).anime
for anime in data:
  anime.moreinfo #to get more info about genres, rating, producers and japanese title
  print(anime.title)
  print(anime.genres + "\n")

#Example 3
data = MyAnimeList('naruto', ('user','password')).manga
for manga in data:
  print(manga.title + "\n")

#Example 4
data = MyAnimeList('one piece', ('user','password')).manga
for manga in data:
  manga.moreinfo #to get more info about genres, author, serializations and japanese title
  print(manga.title)
  print(manga.genres + "\n")
