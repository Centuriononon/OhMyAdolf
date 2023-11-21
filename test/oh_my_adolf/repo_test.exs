defmodule OhMyAdolf.RepoTest do
  use ExUnit.Case, async: false

  alias OhMyAdolf.Repo
  alias Bolt.Sips, as: Neo
  alias Bolt.Sips.Types.{Node}

  setup_all do
    conn = Neo.conn()
    {:ok, conn: conn}
  end

  describe "Repo get_path/4" do
    test "should find existing path and return nodes", context do
      %{conn: conn} = context

      Neo.transaction(
        conn,
        fn conn ->
          Neo.query!(conn, """
          CREATE (a:A)
          CREATE (b:B)
          CREATE (a)-[:RELATES]->(b);
          """)

          node_a = %Node{labels: ["A"]}
          node_b = %Node{labels: ["B"]}
          relation = "RELATES"

          assert {:ok,
                  [
                    %Node{labels: ["A"], properties: %{}},
                    %Node{labels: ["B"], properties: %{}}
                  ]} =
                   Repo.get_path(conn, node_a, node_b, relation)

          Neo.rollback(conn, :end)
        end
      )
    end

    test "should find path by empty nodes", context do
      %{conn: conn} = context

      Neo.transaction(
        conn,
        fn conn ->
          Neo.query!(conn, """
          CREATE (a:A)
          CREATE (b:B)
          CREATE (a)-[:RELATES]->(b);
          """)

          node_a = %Node{}
          node_b = %Node{}
          relation = "RELATES"

          assert {:ok,
                  [
                    %Node{labels: ["A"]},
                    %Node{labels: ["B"]}
                  ]} = Repo.get_path(conn, node_a, node_b, relation)

          Neo.rollback(conn, :end)
        end
      )
    end

    test "should find path by multiple labels", context do
      %{conn: conn} = context

      Neo.transaction(
        conn,
        fn conn ->
          Neo.query!(conn, """
          CREATE (a:A:B)
          CREATE (b:A:B)
          CREATE (a)-[:RELATES]->(b);
          """)

          node_a = %Node{}
          node_b = %Node{}
          relation = "RELATES"

          assert {:ok,
                  [
                    %Node{labels: ["A", "B"]},
                    %Node{labels: ["A", "B"]}
                  ]} =
                   Repo.get_path(conn, node_a, node_b, relation)

          Neo.rollback(conn, :end)
        end
      )
    end

    test "should find path by properties only", context do
      %{conn: conn} = context

      Neo.transaction(
        conn,
        fn conn ->
          Neo.query!(conn, """
          CREATE (a:A {id: 1, done: true})
          CREATE (b_1:A {id: 2, done: false})
          CREATE (b_2:A {id: 2, done: false})
          CREATE (c:A {id: 3, done: true})
          CREATE (a)-[:RELATES]->(b_1)
          CREATE (a)-[:RELATES]->(b_2)
          CREATE (a)-[:RELATES]->(c);
          """)

          node_a = %Node{properties: %{done: true, id: 1}}
          node_b = %Node{properties: %{done: false, id: 2}}
          relation = "RELATES"

          assert {:ok,
                  [
                    %Node{properties: %{"id" => 1, "done" => true}},
                    %Node{properties: %{"id" => 2, "done" => false}}
                  ]} =
                   Repo.get_path(conn, node_a, node_b, relation)

          Neo.rollback(conn, :end)
        end
      )
    end

    test "should find path in bigger graph", context do
      %{conn: conn} = context

      Neo.transaction(
        conn,
        fn conn ->
          Neo.query(conn, """
          CREATE (a1:A {id: 1})
          CREATE (a2:A {id: 2})
          CREATE (a3:A {id: 3})
          CREATE (a4:A {id: 4})
          CREATE (a5:A {id: 5})
          CREATE (a6:A {id: 6})

          CREATE (a1)-[:RELATES]->(a2)
          CREATE (a1)-[:RELATES]->(a5)

          CREATE (a2)-[:RELATES]->(a3)
          CREATE (a2)-[:RELATES]->(a6)

          CREATE (a3)-[:RELATES]->(a4)
          CREATE (a3)-[:RELATES]->(a5)
          """)

          node_start = %Node{labels: ["A"], properties: %{id: 1}}
          node_end = %Node{labels: ["A"], properties: %{id: 6}}
          relation = "RELATES"

          assert {:ok,
                  [
                    %Node{labels: ["A"], properties: %{"id" => 1}},
                    %Node{labels: ["A"], properties: %{"id" => 2}},
                    %Node{labels: ["A"], properties: %{"id" => 6}}
                  ]} = Repo.get_path(conn, node_start, node_end, relation)

          Neo.rollback(conn, :end)
        end
      )
    end
  end

  describe "Repo node_exists?/2" do
    test "should return true on existing node", context do
      %{conn: conn} = context

      Neo.transaction(
        conn,
        fn conn ->
          Neo.query(conn, """
          CREATE (a:A)
          """)

          node = %Node{labels: ["A"]}

          assert true = Repo.node_exists?(conn, node)

          Neo.rollback(conn, :end)
        end
      )
    end

    test "should identify node by muliple labels", context do
      %{conn: conn} = context

      Neo.transaction(
        conn,
        fn conn ->
          Neo.query(conn, """
          CREATE (a:A:B:C)
          """)

          node = %Node{labels: ["A", "B"]}

          assert true = Repo.node_exists?(conn, node)

          Neo.rollback(conn, :end)
        end
      )
    end

    test "should identify node by properties", context do
      %{conn: conn} = context

      Neo.transaction(
        conn,
        fn conn ->
          Neo.query(conn, """
          CREATE (a:A {id: 1, x: "yes"})
          """)

          node = %Node{properties: %{id: 1, x: "yes"}}

          try do
            assert true = Repo.node_exists?(conn, node)
          rescue
            err ->
              IO.puts("error")
              IO.puts(inspect(err))
          end

          Neo.rollback(conn, :end)
        end
      )
    end

    test "should identify existing node without node specs", context do
      %{conn: conn} = context

      Neo.transaction(
        conn,
        fn conn ->
          Neo.query(conn, """
          CREATE (a:A)
          """)

          assert true = Repo.node_exists?(conn, %Node{})

          Neo.rollback(conn, :end)
        end
      )
    end

    test "should return false if there is no any nodes", context do
      %{conn: conn} = context

      Neo.transaction(
        conn,
        fn conn ->
          assert false === Repo.node_exists?(conn, %Node{labels: ["A"]})

          Neo.rollback(conn, :end)
        end
      )
    end

    test "should return false on incorrect properties spec", context do
      %{conn: conn} = context

      Neo.transaction(
        conn,
        fn conn ->
          Neo.query(conn, """
          CREATE (a:A {id: 1, x: "yes"})
          """)

          node = %Node{properties: %{id: 1, x: "no"}}

          assert false === Repo.node_exists?(conn, node)

          Neo.rollback(conn, :end)
        end
      )
    end

    test "should return false on incorrect labels spec", context do
      %{conn: conn} = context

      Neo.transaction(
        conn,
        fn conn ->
          Neo.query(conn, """
          CREATE (a:A {id: 1, x: "yes"})
          """)

          node = %Node{labels: ["B"]}

          assert false === Repo.node_exists?(conn, node)

          Neo.rollback(conn, :end)
        end
      )
    end
  end

  describe "Repo chain_nodes/4" do
    test "should register relation between existing nodes", context do
      %{conn: conn} = context

      Neo.transaction(
        conn,
        fn conn ->
          Neo.query(conn, """
          CREATE (a:A {a: "maximum", d: true})
          CREATE (b:B:C {a: "no"})
          """)

          :ok =
            Repo.chain_nodes(
              conn,
              %Node{labels: ["A"], properties: %{"a" => "m", "d" => true}},
              %Node{labels: ["B", "C"], properties: %{"a" => "no"}},
              "RELATES"
            )

          resp =
            Neo.query!(conn, """
            MATCH (a:A)-[r:RELATES]->(b:B)
            RETURN a, b, r
            """)

          assert %Bolt.Sips.Response{
                   records: [
                     [
                       %Bolt.Sips.Types.Node{properties: %{}, labels: ["A"]},
                       %Bolt.Sips.Types.Node{
                         properties: %{},
                         labels: ["B", "C"]
                       },
                       %Bolt.Sips.Types.Relationship{
                         properties: %{},
                         type: "RELATES"
                       }
                     ]
                   ]
                 } = resp

          Neo.rollback(conn, :end)
        end
      )
    end

    test "should register new nodes and their relationship", context do
      %{conn: conn} = context

      Neo.transaction(
        conn,
        fn conn ->
          :ok =
            Repo.chain_nodes(
              conn,
              %Node{labels: ["A"]},
              %Node{labels: ["B"]},
              "RELATES"
            )

          resp =
            Neo.query!(conn, """
            MATCH (a:A)-[r:RELATES]->(b:B)
            RETURN a, b, r
            """)

          assert %Bolt.Sips.Response{
                   records: [
                     [
                       %Bolt.Sips.Types.Node{properties: %{}, labels: ["A"]},
                       %Bolt.Sips.Types.Node{properties: %{}, labels: ["B"]},
                       %Bolt.Sips.Types.Relationship{
                         properties: %{},
                         type: "RELATES"
                       }
                     ]
                   ]
                 } = resp

          Neo.rollback(conn, :end)
        end
      )
    end

    test "should relate new node to existing one", context do
      %{conn: conn} = context

      Neo.transaction(
        conn,
        fn conn ->
          Neo.query(conn, """
          CREATE (b:B)
          """)

          :ok =
            Repo.chain_nodes(
              conn,
              %Node{labels: ["A"]},
              %Node{labels: ["B"]},
              "RELATES"
            )

          resp =
            Neo.query!(conn, """
            MATCH (a:A)-[r:RELATES]->(b:B)
            RETURN a, b, r
            """)

          assert %Bolt.Sips.Response{
                   records: [
                     [
                       %Bolt.Sips.Types.Node{properties: %{}, labels: ["A"]},
                       %Bolt.Sips.Types.Node{properties: %{}, labels: ["B"]},
                       %Bolt.Sips.Types.Relationship{
                         properties: %{},
                         type: "RELATES"
                       }
                     ]
                   ]
                 } = resp

          Neo.rollback(conn, :end)
        end
      )
    end
  end
end
