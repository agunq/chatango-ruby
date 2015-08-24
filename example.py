from mal import MyAnimeList

#Example 1
data = MyAnimeList('naruto', ('user','password')).anime
for anime in data:
  print(anime.title + "\n")

#Example 2
data = MyAnimeList('naruto', ('user','password')).manga
for manga in data:
  print(manga.title + "\n")
